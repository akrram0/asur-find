# Asur Find — Safe Deep Cleaning Utility for Developers

Windows desktop app (Tauri 2 + React + Go sidecar) that finds and safely cleans
developer clutter. Implements `PRD-safe-deep-cleaning-utility.md`.

## Setup (zero global footprint — PRD §0)

```powershell
. .\setup-env.ps1          # 1. ALWAYS first: sandboxes all toolchains into .tooling\
.\bootstrap-tooling.ps1    # 2. one-time: installs portable Go + Rust into .tooling\
pnpm install               # 3. JS deps (pnpm only — npm/yarn/npx forbidden)
```

## Build & test

```powershell
pnpm test:go     # classification engine unit tests
pnpm build:go    # builds + signs src-go/bin/asur-find-engine.exe (3 MB)
pnpm vite:build  # frontend -> dist/
pnpm build       # tauri build (needs the SAC sign-and-retry helper, see below)
pnpm sign        # signs build outputs with the local dev certificate
```

## Smart App Control (SAC) notes

This dev machine runs with **Smart App Control ON**, which blocks unsigned
executables — including freshly compiled ones. Mitigation:

- `scripts/new-dev-cert.ps1` creates a self-signed **code-signing cert** and
  trusts it in `Cert:\CurrentUser\TrustedPeople`.
- `scripts/sign.ps1` signs every build output. SAC then allows them.
- During `cargo build`, cargo's own intermediate binaries get blocked; use
  `_build-tauri.cmd` (auto-sign-and-retry loop) instead of raw cargo.

## Safety model

- Level 1 (Safe/Clean), Level 2 (Review/Archive), Level 3 (Locked, hardcoded
  blocklist — never bypassable).
- Deletes always go to the Recycle Bin; two-layer confirmation (Go engine
  re-check + UI modal); `DELETE` must be typed for >5 GB or >10 items.
- Every clean is appended to `app-data/audit-log.jsonl`.
