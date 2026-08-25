# Internal helper: cargo build + auto-sign SAC-blocked intermediates, retrying.
# SAC (Smart App Control) blocks cargo's unsigned build-script exes mid-build;
# signing them with the dev cert lets compilation resume. Artifacts cache.
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
"INNER SCRIPT STARTED at $(Get-Date -Format HH:mm:ss)" |
    Out-File -Append (Join-Path $here ".tooling\cargo-build-inner.log")
. (Join-Path $here "setup-env.ps1")
$ErrorActionPreference = "Continue"

$log = Join-Path $here ".tooling\cargo-build-inner.log"
$cert = Get-ChildItem "Cert:\CurrentUser\My\C120CB3FCC0B9E7F68C67BCDB36C6B65E9733CB8"
Set-Location (Join-Path $here "src-tauri")

for ($i = 0; $i -lt 80; $i++) {
    $out = cargo build 2>&1 | Out-String
    $out | Out-File -Append $log
    if ($LASTEXITCODE -eq 0) {
        "BUILD SUCCEEDED" | Out-File -Append $log
        break
    }
    if ($out -notmatch "Application Control policy") {
        "NON-SAC FAILURE - STOPPING" | Out-File -Append $log
        break
    }
    "== SAC block #$($i+1): signing unsigned intermediates ==" | Out-File -Append $log
    Get-ChildItem -Recurse target\debug -Filter *.exe -ErrorAction SilentlyContinue |
        ForEach-Object {
            $s = Get-AuthenticodeSignature $_.FullName
            if ($s.Status -ne "Valid") {
                Set-AuthenticodeSignature $_.FullName -Certificate $cert | Out-Null
            }
        }
}