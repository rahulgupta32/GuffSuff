# Idempotent PowerShell script to setup isolated local development toolchains under .tools/
# NO PRODUCTION CREDENTIALS ARE ACCESSED OR MODIFIED.

$ErrorActionPreference = "Stop"
$ToolDir = Join-Path $PSScriptRoot "..\.tools"

if (-not (Test-Path $ToolDir)) {
    New-Item -ItemType Directory -Path $ToolDir -Force | Out-Null
}

Write-Host "Setting up isolated crypto spike toolchain directory at: $ToolDir"

# Record installed metadata into spikes/crypto-eval/results/toolchains.json
$ToolchainMeta = @{
    timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    hostOS = "Windows 11 Professional (x86_64)"
    isolatedDir = ".tools/"
    jdk = @{
        version = "Eclipse Temurin 21.0.3+9"
        status = "PENDING_LOCAL_INSTALLATION"
    }
    androidSdk = @{
        compileSdk = 34
        minSdk = 26
        ndkVersion = "26.1.10909125"
        status = "PENDING_LOCAL_INSTALLATION"
    }
    rust = @{
        toolchain = "1.82.0-x86_64-pc-windows-msvc"
        targets = @("aarch64-linux-android", "x86_64-linux-android")
        status = "PENDING_LOCAL_INSTALLATION"
    }
}

$ResultsDir = Join-Path $PSScriptRoot "..\spikes\crypto-eval\results"
if (-not (Test-Path $ResultsDir)) {
    New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
}

$ToolchainMeta | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $ResultsDir "toolchains.json")

Write-Host "Toolchain specification recorded in spikes/crypto-eval/results/toolchains.json"
