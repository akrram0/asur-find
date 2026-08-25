package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

// -----------------------------------------------------------------------------
// IPC protocol: line-delimited JSON over stdio (PRD section 1).
//
// Request  -> {"cmd":"scan","id":1,"roots":["C:\\Users\\asur\\projects"],"workers":8}
//          -> {"cmd":"delete","id":2,"paths":["..."],"appDataDir":"..."}
//          -> {"cmd":"classify","id":3,"path":"..."}
// Response <- {"ok":true,"id":1,"entries":[...],"progress":{...},"errors":{}}
//          <- {"ok":true,"id":2,"records":[...]}   | {"ok":false,"id":2,"error":"..."}
//
// No network, no HTTP — local-only stdio pipe (PRD section 1 IPC row).
// -----------------------------------------------------------------------------

type request struct {
	Cmd        string   `json:"cmd"`
	ID         int      `json:"id"`
	Roots      []string `json:"roots,omitempty"`
	Paths      []string `json:"paths,omitempty"`
	AppDataDir string   `json:"appDataDir,omitempty"`
	Workers    int      `json:"workers,omitempty"`
}

type response struct {
	OK       bool            `json:"ok"`
	ID       int             `json:"id"`
	Error    string          `json:"error,omitempty"`
	Entries  []Entry         `json:"entries,omitempty"`
	Progress ScanProgress    `json:"progress,omitempty"`
	Errors   map[string]string `json:"errors,omitempty"`
	Records  []AuditRecord   `json:"records,omitempty"`
	Level    Level           `json:"level,omitempty"`
	Rationale string         `json:"rationale,omitempty"`
	Action   string          `json:"action,omitempty"`
}

func main() {
	in := bufio.NewScanner(os.Stdin)
	in.Buffer(make([]byte, 0, 1024*1024), 16*1024*1024)
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()

	for in.Scan() {
		line := in.Bytes()
		if len(line) == 0 {
			continue
		}
		var req request
		if err := json.Unmarshal(line, &req); err != nil {
			writeResp(out, response{OK: false, Error: fmt.Sprintf("bad request: %v", err)})
			continue
		}
		switch req.Cmd {
		case "scan":
			s := NewScanner(req.Workers)
			entries, err := s.Scan(req.Roots)
			resp := response{
				OK: err == nil, ID: req.ID, Entries: entries,
				Progress: s.Progress(), Errors: s.Errors(),
			}
			if err != nil {
				resp.Error = err.Error()
			}
			writeResp(out, resp)

		case "classify":
			lvl, why := Classify(req.Paths[0], 0, zeroTime())
			writeResp(out, response{
				OK: true, ID: req.ID,
				Level: lvl, Rationale: why, Action: lvl.Action(),
			})

		case "delete":
			appData := req.AppDataDir
			if appData == "" {
				appData = defaultAppDataDir()
			}
			records, err := DeletePaths(req.Paths, appData)
			resp := response{OK: err == nil || records != nil, ID: req.ID, Records: records}
			if err != nil {
				resp.Error = err.Error()
			}
			writeResp(out, resp)

		default:
			writeResp(out, response{OK: false, ID: req.ID,
				Error: fmt.Sprintf("unknown cmd %q", req.Cmd)})
		}
		out.Flush()
	}
}

func writeResp(w *bufio.Writer, r response) {
	b, _ := json.Marshal(r)
	w.Write(b)
	w.WriteByte('\n')
}

// defaultAppDataDir keeps the audit log inside the project tree (PRD section
// 6.1): ./app-data relative to the engine binary's project root.
func defaultAppDataDir() string {
	exe, err := os.Executable()
	if err != nil {
		return `.\app-data`
	}
	root := filepathDir(filepathDir(filepathDir(exe))) // src-go/bin/x.exe -> project root
	return filepath.Join(root, "app-data")
}

func zeroTime() time.Time { return time.Time{} }

func filepathDir(p string) string { return filepath.Dir(p) }