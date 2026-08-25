# =============================================================================
# setup-env.ps1 - Safe Deep Cleaning Utility
#
# MANDATORY first-run script (PRD section 0, rule 3).
# Redirects ALL toolchain state into <project-root>/.tooling/ so the build has
# a zero global footprint. EVERY other script must dot-source this file FIRST:
#
#   . .\setup-env.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

# Project root = directory containing this script
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---- Tooling locations (everything lives inside the project folder) ----------
$env:PNPM_HOME     = Join-Path $ProjectRoot ".tooling\pnpm-home"
$env:CARGO_HOME    = Join-Path $ProjectRoot ".tooling\cargo"
$env:RUSTUP_HOME   = Join-Path $ProjectRoot ".tooling\rustup"
$env:GOPATH        = Join-Path $ProjectRoot ".tooling\go"
$env:GOMODCACHE    = Join-Path $ProjectRoot ".tooling\go\pkg\mod"
$env:GOCACHE       = Join-Path $ProjectRoot ".tooling\go-cache"
$env:GOBIN         = Join-Path $ProjectRoot "src-go\bin"

# Portable toolchain binaries vendored inside .tooling (see bootstrap scripts)
$gnuToolchain = Get-ChildItem "$env:RUSTUP_HOME\toolchains" -Directory -ErrorAction SilentlyContinue |
    Select-Object -First 1
$env:PATH = "$env:PNPM_HOME;" +
            "$env:CARGO_HOME\bin;" +
            "$(if ($gnuToolchain) { $gnuToolchain.FullName + '\bin;' })" +
            (Join-Path $ProjectRoot ".tooling\go-dist\go\bin") + ";" +
            (Join-Path $ProjectRoot "node_modules\.bin") + ";" +
            $env:PATH

# Ensure directories exist
foreach ($dir in @($env:PNPM_HOME, $env:CARGO_HOME, $env:RUSTUP_HOME,
                   $env:GOPATH, $env:GOCACHE, $env:GOBIN)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

Write-Host "[setup-env] Tooling sandboxed under: $(Join-Path $ProjectRoot '.tooling')" -ForegroundColor Green
Write-Host "[setup-env] CARGO_HOME=$env:CARGO_HOME"
Write-Host "[setup-env] RUSTUP_HOME=$env:RUSTUP_HOME"
Write-Host "[setup-env] GOPATH=$env:GOPATH  GOCACHE=$env:GOCACHE"
Write-Host "[setup-env] PNPM_HOME=$env:PNPM_HOME"