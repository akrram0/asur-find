# =============================================================================
# bootstrap-tooling.ps1 - installs ALL build tools into .tooling (no globals).
#
# PRD section 0: nothing may be installed outside this project folder.
# Run AFTER setup-env.ps1:
#   . .\setup-env.ps1
#   .\bootstrap-tooling.ps1
# =============================================================================

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "setup-env.ps1")

$tooling = Join-Path $ProjectRoot ".tooling"

# ---- 1. Portable Go (used by src-go scan engine) ----------------------------
if (-not (Test-Path "$tooling\go-dist\go\bin\go.exe")) {
    Write-Host "[bootstrap] downloading portable Go 1.23.6..."
    $zip = "$tooling\go-dist.zip"
    curl.exe --retry 5 --retry-delay 2 -L -o $zip https://go.dev/dl/go1.23.6.windows-amd64.zip
    New-Item -ItemType Directory -Force -Path "$tooling\go-dist" | Out-Null
    tar -xf $zip -C "$tooling\go-dist"
}
& "$tooling\go-dist\go\bin\go.exe" version

# ---- 2. Rust GNU toolchain (Tauri shell; bundles its own MinGW linker) ------
if (-not (Test-Path "$env:CARGO_HOME\bin\cargo.exe")) {
    Write-Host "[bootstrap] installing rustup stable-x86_64-pc-windows-gnu..."
    if (-not (Test-Path "$tooling\rustup-init.exe")) {
        Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" `
            -OutFile "$tooling\rustup-init.exe" -UseBasicParsing
    }
    & "$tooling\rustup-init.exe" -y --default-toolchain stable-x86_64-pc-windows-gnu `
        --profile minimal --no-modify-path
}
cargo --version

Write-Host "[bootstrap] done — all toolchains live inside $tooling"