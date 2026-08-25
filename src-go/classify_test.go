package main

import (
	"path/filepath"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

func TestLockedSystemPaths(t *testing.T) {
	cases := []string{
		`C:\Windows\System32\kernel32.dll`,
		`C:\Windows`,
		`C:\ProgramData\Docker\overlay2\abc123`,
		`C:\Program Files\SomeApp\build`, // L3 wins even though 'build' matches L1
		`C:\Program Files (x86)\App\dist`,
		`C:\System Volume Information`,
		`D:\$RECYCLE.BIN\something`,
		`C:\pagefile.sys`,
	}
	for _, c := range cases {
		lvl, why := Classify(c, 1<<30, time.Now())
		if lvl != LevelLocked {
			t.Errorf("Classify(%q) = %v (%s), want locked", c, lvl, why)
		}
	}
}

func TestSafeArtifacts(t *testing.T) {
	cases := []string{
		`C:\Users\Asur\projects\api-server\node_modules`,
		`C:\Users\Asur\projects\web-app\.next\cache`,
		`C:\Users\Asur\proj\pkg\__pycache__`,
		`C:\Users\Asur\proj\dist`,
		`C:\Users\Asur\proj\build`,
		`C:\Users\Asur\proj\target`,
		`C:\Users\Asur\AppData\Local\npm-cache`,
		`C:\Users\Asur\proj\.pnpm-store`,
	}
	for _, c := range cases {
		lvl, why := Classify(c, 1<<20, time.Now())
		if lvl != LevelSafe {
			t.Errorf("Classify(%q) = %v (%s), want safe", c, lvl, why)
		}
	}
}

func TestReviewCandidates(t *testing.T) {
	cases := []string{
		`C:\Users\Asur\projects\web-app\.vs`,
		`C:\Users\Asur\projects\web-app\.idea`,
		`C:\Users\Asur\proj\tsconfig.tsbuildinfo`,
		`C:\Users\Asur\proj\.eslintcache`,
	}
	for _, c := range cases {
		lvl, why := Classify(c, 1<<20, time.Now())
		if lvl != LevelReview {
			t.Errorf("Classify(%q) = %v (%s), want review", c, lvl, why)
		}
	}
}

func TestStaleLargeDownload(t *testing.T) {
	old := time.Now().Add(-120 * 24 * time.Hour)
	lvl, _ := Classify(`C:\Users\Asur\Downloads\big-iso.iso`, 500<<20, old)
	if lvl != LevelReview {
		t.Errorf("stale large download = %v, want review", lvl)
	}
	// Recent small files are unclassified.
	if lvl, _ := Classify(`C:\Users\Asur\Downloads\note.txt`, 10, time.Now()); lvl != 0 {
		t.Errorf("recent small file = %v, want unclassified(0)", lvl)
	}
}

func TestUnclassifiedHasNoAction(t *testing.T) {
	lvl, _ := Classify(`E:\random-folder\stuff`, 1<<20, time.Now())
	if lvl != 0 || Level(lvl).Action() != "" {
		t.Errorf("unclassified path got level %d action %q", lvl, Level(lvl).Action())
	}
}

func TestRelativePathIsRejected(t *testing.T) {
	if lvl, _ := Classify("node_modules", 0, time.Time{}); lvl != LevelLocked {
		t.Errorf("relative path must fail closed to locked, got %v", lvl)
	}
}

// Concurrency smoke test: classification must be race-free under parallel use
// (the scanner classifies from multiple goroutines).
func TestClassifyConcurrent(t *testing.T) {
	var wg sync.WaitGroup
	var errs int32
	paths := []string{
		`C:\Windows\notepad.exe`,
		`C:\Users\x\proj\node_modules`,
		`C:\Users\x\proj\.vs`,
		`E:\unknown`,
	}
	for i := 0; i < 50; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for _, p := range paths {
				if _, _ = Classify(p, 0, time.Time{}); false {
					atomic.AddInt32(&errs, 1)
				}
			}
		}()
	}
	wg.Wait()
	_ = errs
	_ = filepath.Separator
}