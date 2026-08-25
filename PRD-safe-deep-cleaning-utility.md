# PRD — Safe Deep Cleaning Utility for Developers
**Platform:** Windows desktop (.exe) · **Aesthetic:** macOS-inspired (Windows-native controls)
**Version:** 1.0 · **Author spec for:** AI coding agent implementation

---

## 0. STRICT RULES (non-negotiable — read before writing any code)

1. **Package manager: `pnpm` only.** Never `npm install`, never `yarn`. Every JS/TS command goes through `pnpm` (`pnpm add`, `pnpm dlx`, `pnpm run`). `npx` is forbidden — use `pnpm dlx` instead (it caches locally, `npx` pollutes the global npm cache).
2. **Zero global footprint.** Nothing is installed outside this project's folder. Explicitly forbidden:
   - Anything under `C:\Program Files\` or `C:\Program Files (x86)\`
   - Anything under `C:\Users\<name>\` **except** paths that live inside the project directory itself
   - Global npm/pnpm packages (`-g` flag is banned)
   - Global Rust toolchain/registry (default `~/.cargo`, `~/.rustup`)
   - Global Go module cache / build cache / GOPATH (default `%USERPROFILE%\go`, `%LOCALAPPDATA%\go-build`)
3. **Concretely, every tool must be redirected to live inside `/project-root/.tooling/`:**

   | Tool | Default (forbidden) location | Required override |
   |---|---|---|
   | pnpm store | `%LOCALAPPDATA%\pnpm-store` | `pnpm config set store-dir ./.tooling/pnpm-store` (project `.npmrc`: `store-dir=./.tooling/pnpm-store`) |
   | pnpm home / cache | `%LOCALAPPDATA%\pnpm` | set `PNPM_HOME` env var (via project `.env` / launch script) to `./.tooling/pnpm-home` |
   | Cargo registry | `C:\Users\<name>\.cargo` | set `CARGO_HOME=./.tooling/cargo` |
   | Rustup toolchains | `C:\Users\<name>\.rustup` | set `RUSTUP_HOME=./.tooling/rustup` |
   | GOPATH | `%USERPROFILE%\go` | set `GOPATH=./.tooling/go` |
   | Go module cache | `%USERPROFILE%\go\pkg\mod` | set `GOMODCACHE=./.tooling/go/pkg/mod` |
   | Go build cache | `%LOCALAPPDATA%\go-build` | set `GOCACHE=./.tooling/go-cache` |
   | Go binary build output | project root pollution | build output goes to `./src-go/bin` only |

   These env vars must be set in a single `setup-env.ps1` / `setup-env.sh` script at the project root that every other script sources first. **The AI agent must generate this script before anything else.**
4. All build artifacts (`node_modules`, `.tooling/`, `target/`, `dist/`, `.venv`) stay inside the project folder and are `.gitignore`d.
5. Never auto-delete a user file without an explicit confirmation dialog naming the exact path and size.

---

## 1. Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Shell / window | **Tauri 2.0** (Rust core) | Small binary, native Windows Mica/Acrylic blur API, no Chromium bloat |
| UI | **React + TypeScript + Tailwind CSS** | 1:1 translation of the Figma spec below; Tailwind maps directly to the spacing/radius tokens in §3 |
| Package manager (JS) | **pnpm** | Per Strict Rule 1 |
| Scan/classification engine | **Go** (compiled sidecar binary, `go build`) | Native filesystem walk speed on large drives, tiny static binary, near-zero memory overhead vs. an interpreter — chosen specifically to keep scanning **fast and lightweight** |
| IPC | Tauri command → Go sidecar over **stdio JSON**, no network/HTTP | Local-only, fast, no attack surface |
| Safety layer | Confirmation modal (frontend) + re-validation in Go before any delete | Belt-and-suspenders: UI cannot bypass the engine's own Level-3 lock check (see §6.1) |
| Packaging | `tauri build` → single `.exe` / `.msi` | Bundles frontend + Rust shell + Go sidecar together |

---

## 2. Project Structure

```
/project-root
├── setup-env.ps1              # sets CARGO_HOME, RUSTUP_HOME, PNPM_HOME, etc. — run first, always
├── .npmrc                      # store-dir=./.tooling/pnpm-store
├── .gitignore
├── package.json                # pnpm workspace root
├── pnpm-workspace.yaml
├── src/                         # React + TS + Tailwind frontend
│   ├── components/
│   │   ├── TitleBar.tsx
│   │   ├── Sidebar.tsx
│   │   ├── TreemapPanel.tsx
│   │   ├── FileRow.tsx
│   │   └── icons/               # hand-built SVG icon set (see §5)
│   ├── styles/tokens.css        # design tokens from §3, as CSS variables
│   └── App.tsx
├── src-tauri/                   # Rust shell
│   ├── tauri.conf.json
│   ├── Cargo.toml
│   └── src/main.rs
├── src-go/                      # scan + classification engine (fast, lightweight)
│   ├── go.mod
│   ├── go.sum
│   ├── main.go                   # stdio JSON IPC entrypoint
│   ├── scanner.go                 # concurrent filesystem walk (goroutines + worker pool)
│   ├── classify.go                # Level 1/2/3 rules (see §6)
│   ├── deleter.go                  # Recycle Bin move + audit log (see §6.1)
│   └── bin/                        # build output, .gitignored
└── .tooling/                     # ALL local caches (git-ignored) — see §0
```

---

## 3. Design Tokens (exact, pixel-level)

### 3.1 Window
- Size: **1024 × 768**
- Corner radius: **12px**
- Drop shadow: `0px 8px 32px rgba(0,0,0,0.18)` (light) / `rgba(0,0,0,0.4)` (dark)

### 3.2 Color Palette

| Token | Light | Dark |
|---|---|---|
| `--bg-window` | `#FFFFFF` | `#1E1E1E` |
| `--bg-titlebar` | `#F5F5F7` | `#2C2C2E` |
| `--bg-sidebar-glass` | `#F5F5F7` @ 72% + backdrop-blur 40px | `#000000` @ 45% + backdrop-blur 40px |
| `--bg-card` | `#F5F5F7` | `#2C2C2E` |
| `--text-primary` | `#1D1D1F` | `#F5F5F7` |
| `--text-secondary` | `#6E6E73` | `#98989D` |
| `--divider` | `#E5E5EA` | `#38383A` |
| `--accent` | `#007AFF` | `#0A84FF` |
| `--safe` | `#34C759` | `#30D158` |
| `--review` | `#FF9F0A` | `#FF9F0A` |
| `--locked` | `#8E8E93` @ 50% opacity | `#8E8E93` @ 50% opacity |

### 3.3 Typography (Inter — SF Pro fallback)

| Use | Size | Weight |
|---|---|---|
| Window title | 13px | Semi Bold |
| Page heading ("Dashboard") | 24px | Bold |
| Greeting ("Hello, Asur") | 13px | Semi Bold, accent color |
| Page subtitle | 13px | Regular |
| Card/section header | 14–16px | Semi Bold |
| Sidebar nav (active) | 13px | Semi Bold |
| Sidebar nav (inactive) | 13px | Medium |
| Category legend label | 12px | Medium |
| Category legend header ("CATEGORIES") | 11px | Semi Bold |
| File name | 13px | Medium |
| File path | 11px | Regular |
| File size | 12px | Semi Bold |
| Button label | 11–12px | Semi Bold |

### 3.4 Radius & Spacing Scale
- Radius: `3px` (progress bar), `6px` (treemap blocks), `8px` (buttons, nav pill), `10px` (cards, file rows), `12px` (window, panel)
- Base spacing unit: `4px` grid throughout (8, 12, 16, 20, 24, 32px margins)

---

## 4. Exact Layout Map

All coordinates are **relative to their immediate parent container** — this distinction matters (a positioning bug during prototyping came from mixing this up: always attach a node to its parent *before* setting x/y).

### 4.1 Title bar — `0,0` → `1024×52`
- Background `--bg-titlebar`, 1px bottom divider
- Title text: centered across full width, vertically centered in the 52px bar
- **Rescan button:** `x=796, y=12, w=112, h=28`, radius 8, `--accent` fill, white refresh-icon (14×14) + "Rescan" label
- **Window controls (Windows-style, top-right — NOT macOS traffic lights):**
  - Close: `28×28` box, right edge `8px` from window edge
  - Maximize: `28×28`, `4px` gap left of Close
  - Minimize: `28×28`, `4px` gap left of Maximize
  - All three: monochrome line icons (minimize = horizontal line, maximize = square outline, close = X), no fill backgrounds, `--text-primary` stroke

### 4.2 Sidebar — `0,52` → `220×716`
- Glassmorphic: `--bg-sidebar-glass` + backdrop blur, 1px right divider
- **Storage card:** `16,20, w188,h64`, radius 10, white/dark @60%
  - Label "512 GB Used of 1 TB" at `28,32`
  - Progress track `28,54, w164,h6`, radius 3, `--divider`
  - Progress fill `28,54, w<proportional>,h6`, radius 3, `--accent`
- **Nav list:** starts at `y=104`, each item **36px tall, 44px row pitch** (8px gap)
  - Active pill background: `12,ny, w196,h36`, radius 8, `--accent` @ 12%
  - Icon: `16×16` at `x=24, y=ny+10`
  - Label: `x=52, y=ny, w=140, h=36`, vertically centered
  - Items in order: Dashboard (active), Dev Clutter, Large Files, Duplicates, Settings
- **Category legend:** header "CATEGORIES" 16px below last nav item; each row **26px pitch**, 8×8 dot at `x=24`, label at `x=40`

### 4.3 Main content — `220,52` → `804×716`
- Header block:
  - "Hello, Asur" → `32,20`
  - "Dashboard" → `32,40`
  - "Storage overview for this PC" → `32,74`
- **Storage Composition card:** `32,104, w740,h220`, radius 12
  - Label at `52,124`
  - Treemap blocks (all relative to main frame, 2px white/dark gap stroke between blocks, radius 6):
    | Block | x,y | w×h | Fill |
    |---|---|---|---|
    | Dev Clutter (210 GB) | 52,156 | 280×150 | `--locked` @90% |
    | Node Modules (64 GB) | 340,156 | 170×70 | `--locked` @65% |
    | Build Caches (38 GB) | 340,232 | 170×74 | `--locked` @45% |
    | Large Files (52 GB) | 518,156 | 120×70 | `--accent` @85% |
    | Review sliver | 518,232 | 120×36 | `--review` @60% |
    | Safe sliver | 518,270 | 120×36 | `--safe` @60% |
    | System (locked) | 646,156 | 114×150 | flat gray, full opacity |
- **Details list:** heading at `32,344`; rows start at `y=380`, each row **56px tall, 64px pitch** (8px gap), full width `740px` starting `x=32`, radius 10, 1px divider stroke
  - Status icon: 20×20 circle at `~44, row+18`
  - File name: `84, row+8, w400,h20`
  - File path: `84, row+30, w400,h16`
  - File size: right-aligned, `540, row, w80,h56`
  - Action button (Level 1/2 only): `28px` tall, right-aligned to `x=690–786`, icon + label, white on `--safe`/`--review`
  - Locked rows: entire row content at 50% opacity, "Protected" label instead of a button, no action

---

## 5. Icon Set (hand-built, no external icon library)

Build these as inline SVG React components matching the vector geometry already prototyped:
- **Sidebar:** `IconGrid` (2×2 squares), `IconFolder`, `IconDoc` (rect + 2 lines), `IconLayers` (2 overlapping squares), `IconSettings` (3 sliders)
- **Status:** `IconCheck` (safe, white on green), `IconExclaim` (review, white bar+dot on orange), `IconLock` (locked, gray padlock at 50% opacity)
- **Action buttons:** `IconCheck` (Clean), `IconMagnifier` (Review), `IconArchiveBox` (Archive)
- **Title bar:** `IconRefresh` (partial ring, Rescan), `IconMinimize`, `IconMaximize`, `IconClose`

All icons monochrome, stroke-based where possible, matching the sizes specified in §3.3/§4.

---

## 6. Classification Logic (Go — the actual product)

This is rules-based, **not** ML/heuristic-guessed. Deterministic and auditable. Chosen in Go specifically so a full-drive scan stays fast and lightweight (goroutine worker pool over the filesystem walk, no interpreter startup cost).

- **Level 1 — Safe to Clean:** regenerable artifacts matched against a known-safe pattern list — `node_modules/`, `.next/cache`, `__pycache__/`, `dist/`, `build/`, dangling Docker images/overlay2 layers, npm/pnpm/yarn caches. Action: `Clean` (delete with confirmation).
- **Level 2 — Needs Review:** large but not 100% certain — old build caches, `.vs/` cache folders, IDE indexes, large downloads folder items untouched >90 days. Action: `Review` or `Archive` (move, don't delete).
- **Level 3 — Locked/System:** anything under Windows system paths (`C:\Windows\`, `C:\ProgramData\`), files owned by a currently-running process, or anything matched against a hardcoded blocklist. **No action button, ever.** Opacity 50% in UI to visually communicate "don't touch."
- **Hard rule:** no destructive action fires without a confirmation dialog listing exact path + size. No "select all and clean" without per-item review on first run.

### 6.1 Security Confirmation — Clean action (mandatory, two-layer)

**Layer 1 — Go engine re-check (cannot be bypassed from the UI):** before executing any delete, `deleter.go` independently re-runs the Level-3 blocklist check on the exact path it's about to touch. If the path matches Level 3, the engine refuses and returns an error — even if a compromised or buggy frontend somehow sent a Clean request for it.

**Layer 2 — Confirmation modal (frontend, matches design system in §3):**
- Trigger: every single Clean or Archive action, no exceptions — no "don't ask again."
- Overlay: full-window dim, `rgba(0,0,0,0.35)`
- Modal card: centered, `420px` wide, radius `14px`, `--bg-card`, `24px` padding, drop shadow matching §3.1
- Header: status-colored icon circle (24×24, reuses `IconCheck`/`IconExclaim` from §5) + title `"Confirm Clean"` (16px Semi Bold)
- Body:
  - Exact path, monospace, 12px, `--text-secondary`
  - Size, bold, 14px
  - Classification badge (Level 1 = green "Safe", Level 2 = orange "Review")
  - One-line rationale, e.g. *"Regenerated automatically by npm/pnpm — safe to remove."*
- **Escalation for large/batch actions:** if total size > 5 GB or item count > 10, the confirm button is disabled until the user types `DELETE` into a text field (prevents a single misclick from wiping a large amount of data)
- Deletion behavior: **always moves to the Windows Recycle Bin**, never a permanent erase — a secondary, separately-labeled "Permanently delete" toggle is required to skip the Recycle Bin, and toggling it adds its own extra confirmation step
- Every executed Clean is appended to a local audit log (`./app-data/audit-log.jsonl`, inside the project's user-data folder, never global) with timestamp, path, size, and classification level
- Footer buttons: `Cancel` (36px, outline, `--text-secondary`) and `Move to Recycle Bin` (36px, radius 8, `--safe` or `--review` fill) — right-aligned, `8px` gap
- Post-action: toast/snackbar confirming what was removed, with an `Undo` action available for a short window (restores from Recycle Bin)

Example Windows-appropriate dataset for the Details list (replaces the macOS placeholder paths used in the prototype):
1. `node_modules/` — `C:\Users\Asur\projects\api-server` — 6.2 GB — Level 1 — Clean
2. `.next\cache` — `C:\Users\Asur\projects\web-app` — 1.8 GB — Level 2 — Review
3. `.vs\cache` — `C:\Users\Asur\projects\web-app` — 9.4 GB — Level 2 — Archive
4. `System Volume Information` — `C:\` — 0.3 GB — Level 3 — Protected
5. Docker `overlay2` images — `C:\ProgramData\Docker\overlay2` — 14.1 GB — Level 1 — Clean

---

## 7. Acceptance Criteria for the AI Agent

- [ ] `setup-env` script exists and is sourced by every other script; no tool writes outside `.tooling/` or the project folder
- [ ] `pnpm install` and `pnpm build` succeed with zero global side effects (verify via a clean Windows sandbox — nothing new appears under `Program Files` or the user profile except the final `.exe`/`.msi`)
- [ ] Window renders at exactly 1024×768 with 12px corner radius and the specified drop shadow
- [ ] Sidebar shows real backdrop blur (Windows Acrylic/Mica via Tauri), not a CSS approximation
- [ ] Every coordinate in §4 is implemented as spec'd — no eyeballed spacing
- [ ] Window controls are Windows-style (min/max/close, top-right) — no macOS traffic lights anywhere
- [ ] All icons are custom SVG per §5 — no icon font/library dependency
- [ ] Classification logic lives in `src-go/classify.go` as explicit rules, unit-tested, with the Level 3 blocklist hardcoded and never bypassable from the UI
- [ ] Scan engine is Go, not Python/Node — verify a full-drive scan completes with low memory footprint (goroutine worker pool, no interpreter overhead)
- [ ] No delete action executes without the two-layer confirmation in §6.1: Go engine re-check **and** frontend modal
- [ ] Every Clean action defaults to Recycle Bin, never permanent delete, unless the separate "Permanently delete" toggle is explicitly set
- [ ] Batch/large Clean actions (>5GB or >10 items) require typing `DELETE` to enable the confirm button
- [ ] Every executed Clean is written to `./app-data/audit-log.jsonl`
