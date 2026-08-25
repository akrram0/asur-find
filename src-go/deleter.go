package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

// ErrLockedByEngine is returned when the Layer-1 re-check catches a request
// to delete a protected path — even if the UI asked for it (PRD section 6.1).
var ErrLockedByEngine = errors.New("engine refused: path matches hardcoded Level-3 blocklist")

const (
	foDelete          = 0x0003
	fofAllowUndo      = 0x0040 // send to Recycle Bin instead of permanent erase
	fofNoConfirmation = 0x0010
	fofSilent         = 0x0004
	fofNoErrorUI      = 0x0800
)

// shFileOpStruct mirrors SHFILEOPSTRUCTW (64-bit layout with natural padding).
type shFileOpStruct struct {
	hwnd          uintptr
	func_         uint32
	from, to      *uint16
	flags         uint16
	anyAborted    int32
	nameMappings  uintptr
	progressTitle *uint16
}

var (
	shell32          = syscall.NewLazyDLL("shell32.dll")
	procSHFileOperation = shell32.NewProc("SHFileOperationW")
)

// moveToRecycleBin moves path to the Windows Recycle Bin via SHFileOperationW.
// NEVER performs a permanent delete (PRD section 6.1: Recycle Bin is mandatory;
// permanent delete requires an explicit separate toggle handled in the UI with
// its own confirmation, and is intentionally not exposed by this function yet).
func moveToRecycleBin(path string) error {
	if !filepath.IsAbs(path) {
		return fmt.Errorf("refusing relative path %q", path)
	}
	// SHFileOperationW wants a DOUBLE-null-terminated path list.
	// syscall.UTF16PtrFromString rejects any embedded NUL (EINVAL), so build
	// the buffer manually: [chars..., 0, 0].
	u := syscall.StringToUTF16(path) // deprecated but exactly right here
	buf := make([]uint16, len(u))
	copy(buf, u)
	p := &buf[0]
	op := shFileOpStruct{
		func_: foDelete,
		flags: fofAllowUndo | fofNoConfirmation | fofSilent | fofNoErrorUI,
		from:  p,
	}
	ret, _, _ := procSHFileOperation.Call(uintptr(unsafe.Pointer(&op)))
	if ret != 0 {
		return fmt.Errorf("SHFileOperation failed with code %d for %q", ret, path)
	}
	return nil
}

// AuditRecord is appended as one JSON line to app-data/audit-log.jsonl.
type AuditRecord struct {
	Timestamp string `json:"timestamp"`
	Path      string `json:"path"`
	SizeBytes int64  `json:"sizeBytes"`
	Level     int    `json:"level"`
	Result    string `json:"result"` // "recycled" | "refused"
}

// AuditLog writes audit records inside the project's user-data folder only.
func AuditLog(appDataDir string, rec AuditRecord) error {
	if err := os.MkdirAll(appDataDir, 0o755); err != nil {
		return err
	}
	f, err := os.OpenFile(filepath.Join(appDataDir, "audit-log.jsonl"),
		os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644)
	if err != nil {
		return err
	}
	defer f.Close()
	b, err := json.Marshal(rec)
	if err != nil {
		return err
	}
	_, err = f.Write(append(b, '\n'))
	return err
}

// DeletePaths executes Clean actions with the mandatory Layer-1 engine check:
// each path is INDEPENDENTLY re-classified right before deletion. Any Level-3
// match aborts that item and is recorded as "refused" in the audit log.
func DeletePaths(paths []string, appDataDir string) ([]AuditRecord, error) {
	var out []AuditRecord
	var firstErr error
	for _, p := range paths {
		lvl, _ := Classify(p, 0, time.Time{}) // size/mtime irrelevant for L3 check
		rec := AuditRecord{
			Timestamp: time.Now().UTC().Format(time.RFC3339Nano),
			Path:      p,
			Level:     int(lvl),
		}
		if lvl == LevelLocked || lvl == 0 {
			rec.Result = "refused"
			out = append(out, rec)
			_ = AuditLog(appDataDir, rec)
			if firstErr == nil {
				firstErr = fmt.Errorf("%w: %s", ErrLockedByEngine, p)
			}
			continue
		}
		if err := moveToRecycleBin(p); err != nil {
			rec.Result = "refused"
			out = append(out, rec)
			_ = AuditLog(appDataDir, rec)
			if firstErr == nil && !strings.Contains(err.Error(), "code 2") {
				firstErr = err
			}
			continue
		}
		rec.Result = "recycled"
		out = append(out, rec)
		if err := AuditLog(appDataDir, rec); err != nil && firstErr == nil {
			firstErr = err
		}
	}
	return out, firstErr
}