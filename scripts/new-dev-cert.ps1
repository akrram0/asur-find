# =============================================================================
# new-dev-cert.ps1 - one-time: creates the local dev code-signing certificate.
# The certificate lets built binaries run while Smart App Control is ON
# (SAC accepts signatures that chain to a cert in TrustedPeople/Root).
# =============================================================================
$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

$thumb = "C120CB3FCC0B9E7F68C67BCDB36C6B65E9733CB8" # current dev cert, if present
if (Get-ChildItem "Cert:\CurrentUser\My\$thumb" -ErrorAction SilentlyContinue) {
    Write-Host "[cert] Dev signing cert already exists ($thumb)"
    return
}

$cert = New-SelfSignedCertificate -Type CodeSigningCert `
    -Subject "CN=AsurFind Dev Signing" `
    -KeyUsage DigitalSignature `
    -FriendlyName "AsurFind Dev" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter (Get-Date).AddYears(3)

New-Item -ItemType Directory -Force -Path "$ProjectRoot\.tooling\certs" | Out-Null
$pw = ConvertTo-SecureString "devonly" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "$ProjectRoot\.tooling\certs\asur-find-dev.pfx" -Password $pw | Out-Null
Export-Certificate -Cert $cert -FilePath "$ProjectRoot\.tooling\certs\asur-find-dev.cer" | Out-Null

# Trust it without UI prompts via the user-level TrustedPeople store.
Import-Certificate -FilePath "$ProjectRoot\.tooling\certs\asur-find-dev.cer" `
    -CertStoreLocation "Cert:\CurrentUser\TrustedPeople" | Out-Null

Write-Host "[cert] Created + trusted: $($cert.Thumbprint)"
Write-Host "[cert] Update `$Thumbprint in scripts\sign.ps1 to this value."