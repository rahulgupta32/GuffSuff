# Verification script for local crypto spike toolchains

$ErrorActionPreference = "Continue"

Write-Host "=== VERIFYING CRYPTO SPIKE TOOLCHAINS ==="

function Check-Command($cmd, $arg) {
    try {
        $res = & $cmd $arg 2>&1
        Write-Host "[PRESENT] $cmd : $($res[0])"
        return $true
    } catch {
        Write-Host "[MISSING] $cmd"
        return $false
    }
}

$jdkPresent = Check-Command "java" "-version"
$rustPresent = Check-Command "cargo" "--version"
$flutterPresent = Check-Command "flutter" "--version"

Write-Host "Toolchain verification completed."
