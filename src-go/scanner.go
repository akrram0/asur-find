package main

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sync"
	"sync/atomic"
	"time"
)

// Entry is one scanned filesystem node sent back to the UI.
type Entry struct {
	Path      string  `json:"path"`
	SizeBytes int64   `json:"sizeBytes"`
	IsDir     bool    `json:"isDir"`
	ModTime   string  `json:"modTime"` // RFC3339
	Level     Level   `json:"level"`
	Rationale string  `json:"rationale,omitempty"`
	Action    string  `json:"action,omitempty"`
	Error     *string `json:"error,omitempty"`
}

// ScanProgress is emitted periodically while walking.
type ScanProgress struct {
	DirsWalked uint64 `json:"dirsWalked"`
	FilesSeen  uint64 `json:"filesSeen"`
}

// Scanner walks the filesystem concurrently with a bounded worker pool.
//
// Concurrency model: directories are pushed onto dirCh; `pending` tracks how
// many are queued/processing. Workers may enqueue children while draining.
// The channel is only closed once pending hits zero, so no send-after-close
// race can occur.
type Scanner struct {
	workers int
	dirCh   chan string
	pending sync.WaitGroup

	dirsWalked atomicCounter
	filesSeen  atomicCounter

	mu      sync.Mutex
	entries []Entry
	errs    map[string]string
}

type atomicCounter struct{ n uint64 }

func (c *atomicCounter) add(delta uint64) { atomic.AddUint64(&c.n, delta) }
func (c *atomicCounter) get() uint64      { return atomic.LoadUint64(&c.n) }

func NewScanner(workers int) *Scanner {
	if workers < 1 {
		workers = 8 // PRD: goroutine worker pool; 8 is a good default on NVMe
	}
	return &Scanner{
		workers: workers,
		dirCh:   make(chan string, 1024),
		errs:    map[string]string{},
	}
}

// Scan walks every root concurrently and returns classified entries.
func (s *Scanner) Scan(roots []string) ([]Entry, error) {
	for _, root := range roots {
		s.enqueue(filepath.Clean(root))
	}

	var wg sync.WaitGroup
	for i := 0; i < s.workers; i++ {
		wg.Add(1)
		go s.worker(&wg)
	}

	s.pending.Wait() // all queued dirs fully processed
	close(s.dirCh)   // safe: nothing enqueues after pending hits zero
	wg.Wait()

	return s.entries, nil
}

func (s *Scanner) enqueue(dir string) {
	s.pending.Add(1)
	s.dirCh <- dir
}

func (s *Scanner) worker(wg *sync.WaitGroup) {
	defer wg.Done()
	for dir := range s.dirCh {
		s.dirsWalked.add(1)
		children, err := readDirNames(dir)
		if err != nil {
			s.recordError(dir, err)
			s.pending.Done()
			continue
		}
		for _, full := range children { // Glob already yields full paths
			info, err := os.Lstat(full)
			if err != nil {
				s.recordError(full, err)
				continue
			}
			s.filesSeen.add(1)

			entry := Entry{
				Path:      full,
				SizeBytes: info.Size(),
				IsDir:     info.IsDir(),
				ModTime:   info.ModTime().UTC().Format(time.RFC3339),
			}
			entry.Level, entry.Rationale = Classify(full, info.Size(), info.ModTime())
			entry.Action = entry.Level.Action()
			s.appendEntry(entry)

			if info.IsDir() && !isSymlink(info) {
				s.enqueue(full)
			}
		}
		s.pending.Done()
	}
}

func (s *Scanner) appendEntry(e Entry) {
	s.mu.Lock()
	s.entries = append(s.entries, e)
	s.mu.Unlock()
}

func (s *Scanner) recordError(path string, err error) {
	s.mu.Lock()
	s.errs[path] = err.Error()
	s.mu.Unlock()
}

// Progress snapshots current counters for IPC progress events.
func (s *Scanner) Progress() ScanProgress {
	return ScanProgress{
		DirsWalked: s.dirsWalked.get(),
		FilesSeen:  s.filesSeen.get(),
	}
}

// Errors returns a copy of per-path walk errors (permission denied etc).
func (s *Scanner) Errors() map[string]string {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make(map[string]string, len(s.errs))
	for k, v := range s.errs {
		out[k] = v
	}
	return out
}

func isSymlink(info fs.FileInfo) bool { return info.Mode()&fs.ModeSymlink != 0 }

func readDirNames(dir string) ([]string, error) {
	entries, err := filepath.Glob(filepath.Join(dir, "*"))
	if err != nil {
		return nil, fmt.Errorf("glob %s: %w", dir, err)
	}
	return entries, nil
}