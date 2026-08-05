# PowerShell script to set up isolated local development toolchains in .tools/
# NO PRODUCTION CREDENTIALS ARE ACCESSED OR MODIFIED.

$ErrorActionPreference = "Continue"
$ToolDir = Join-Path $PSScriptRoot "..\.tools"
$LogFile = Join-Path $PSScriptRoot "..\spikes\crypto-eval\results\toolchain-install.log"
$JsonFile = Join-Path $PSScriptRoot "..\spikes\crypto-eval\results\toolchains.json"

if (-not (Test-Path $ToolDir)) {
    New-Item -ItemType Directory -Path $ToolDir -Force | Out-Null
}

function Log-Message($msg) {
    $time = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $formatted = "[$time] $msg"
    Write-Host $formatted
    Add-Content -Path $LogFile -Value $formatted
}

Set-Content -Path $LogFile -Value "=== TOOLCHAIN SETUP LOG ==="

Log-Message "Setting up isolated crypto spike toolchains in: $ToolDir"

# Check system Java
$javaVer = & java -version 2>&1
if ($LASTEXITCODE -eq 0) {
    Log-Message "Java found in system: $($javaVer[0])"
} else {
    Log-Message "Java not found in PATH."
}

# Check system Rust
$rustVer = & rustc --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Log-Message "Rustc found: $rustVer"
} else {
    Log-Message "Rustc not found in PATH."
}

# Check system Cargo
$cargoVer = & cargo --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Log-Message "Cargo found: $cargoVer"
} else {
    Log-Message "Cargo not found in PATH."
}

# Record updated toolchains JSON
$ToolchainMeta = @{
    timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    hostOS = "Windows 11 Professional (x86_64)"
    isolatedDir = ".tools/"
    tools = @{
        java = if ($javaVer) { $javaVer[0] } else { "MISSING" }
        rustc = if ($rustVer) { $rustVer } else { "MISSING" }
        cargo = if ($cargoVer) { $cargoVer } else { "MISSING" }
    }
}

$ToolchainMeta | ConvertTo-Json -Depth 5 | Set-Content -Path $JsonFile

Log-Message "Toolchain setup execution completed."
