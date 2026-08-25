# =============================================================================
# sign.ps1 - signs build outputs with the local dev code-signing certificate
# so they can run while Windows Smart App Control is ON.
#
#   . .\setup-env.ps1
#   .\scripts\sign.ps1            # signs all build artifacts
#
# First-time setup (done once):
#   .\scripts\new-dev-cert.ps1
# =============================================================================
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

$Thumbprint = "C120CB3FCC0B9E7F68C67BCDB36C6B65E9733CB8" # CN=AsurFind Dev Signing
$cert = Get-ChildItem "Cert:\CurrentUser\My\$Thumbprint" -ErrorAction SilentlyContinue
if (-not $cert) { throw "Dev signing cert $Thumbprint not found - run scripts\new-dev-cert.ps1" }

$targets = @(
    "src-go\bin\asur-find-engine.exe",
    "src-tauri\target\debug\asur-find.exe",
    "src-tauri\target\release\asur-find.exe"
)

foreach ($t in $targets) {
    $p = Join-Path $ProjectRoot $t
    if (Test-Path $p) {
        $sig = Set-AuthenticodeSignature -FilePath $p -Certificate $cert
        Write-Host "[sign] $t -> $($sig.Status)"
    }
}