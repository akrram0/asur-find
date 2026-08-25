// Asur Find — Tauri 2 shell.
// Bridges the frontend to the Go scan/classify/delete sidecar over stdio JSON.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::{Deserialize, Serialize};
use std::io::{BufReader, Write};
use std::path::PathBuf;
use std::process::{Command, Stdio};
use tauri::Manager;

#[derive(Deserialize, Serialize)]
struct EngineRequest {
    cmd: String,
    id: i32,
    #[serde(default)]
    roots: Vec<String>,
    #[serde(default)]
    paths: Vec<String>,
}

#[derive(Serialize, Deserialize)]
struct IpcEntry {
    path: String,
    sizeBytes: i64,
    isDir: bool,
    modTime: String,
    level: i32,
    rationale: String,
    action: String,
}

#[derive(Serialize, Deserialize, Clone)]
struct IpcRecord {
    timestamp: String,
    path: String,
    sizeBytes: i64,
    level: i32,
    result: String,
}

#[derive(Deserialize)]
struct EngineResponse {
    ok: bool,
    #[serde(default)]
    error: String,
    #[serde(default)]
    entries: Vec<IpcEntry>,
    #[serde(default)]
    records: Vec<IpcRecord>,
}

/// Locate the Go engine binary. In dev it lives at <root>/src-go/bin;
/// in production builds it sits next to the app executable.
fn engine_path(app: &tauri::AppHandle) -> Result<PathBuf, String> {
    let candidates = [
        app.path().resource_dir().ok().map(|d| d.join("asur-find-engine.exe")),
        std::env::current_exe().ok().and_then(|d| Some(d.parent()?.parent()?.join("src-go/bin/asur-find-engine.exe"))),
        Some(PathBuf::from("../src-go/bin/asur-find-engine.exe")),
    ];
    for c in candidates.iter().flatten() {
        if c.exists() {
            return Ok(c.clone());
        }
    }
    Err("Go engine binary not found — run `pnpm build:go` first".into())
}

/// One request -> one response over the sidecar's stdin/stdout (PRD §1 IPC).
fn call_engine(
    app: &tauri::AppHandle,
    req: &EngineRequest,
) -> Result<EngineResponse, String> {
    let exe = engine_path(app)?;
    let mut child = Command::new(exe)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|e| format!("engine spawn failed: {e}"))?;

    let payload = serde_json::to_string(req).map_err(|e| e.to_string())?;
    child
        .stdin
        .take()
        .unwrap()
        .write_all(payload.as_bytes())
        .and_then(|_| Ok(()))
        .map_err(|e| format!("engine write failed: {e}"))?;

    let out = child.wait_with_output().map_err(|e| e.to_string())?;
    let stdout = String::from_utf8_lossy(&out.stdout);
    let line = stdout.lines().next().unwrap_or("{}");
    serde_json::from_str(line).map_err(|e| format!("bad engine reply: {e}: {line}"))
}

#[tauri::command]
fn scan_roots(app: tauri::AppHandle, roots: Vec<String>) -> Result<Vec<IpcEntry>, String> {
    let resp = call_engine(
        &app,
        &EngineRequest { cmd: "scan".into(), id: 1, roots, paths: vec![] },
    )?;
    if resp.ok {
        Ok(resp.entries)
    } else {
        Err(resp.error)
    }
}

#[tauri::command]
fn clean_paths(app: tauri::AppHandle, paths: Vec<String>) -> Result<Vec<IpcRecord>, String> {
    let resp = call_engine(
        &app,
        &EngineRequest { cmd: "delete".into(), id: 2, roots: vec![], paths },
    )?;
    if !resp.records.is_empty() || resp.ok {
        Ok(resp.records)
    } else {
        Err(resp.error)
    }
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_window_state::Builder::default().build())
        .invoke_handler(tauri::generate_handler![scan_roots, clean_paths])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}