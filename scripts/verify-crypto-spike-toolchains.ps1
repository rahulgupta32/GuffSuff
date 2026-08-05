# PowerShell script to verify all required executable toolchains safely

$ErrorActionPreference = "Continue"
$LogFile = Join-Path $PSScriptRoot "..\spikes\crypto-eval\results\toolchain-install.log"

function Test-Binary($cmd, $arg) {
    try {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $cmd
        $pinfo.Arguments = $arg
        $pinfo.RedirectStandardOutput = $true
        $pinfo.RedirectStandardError = $true
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true

        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $started = $p.Start()

        if ($started) {
            $p.WaitForExit(3000)
            $out = $p.StandardOutput.ReadToEnd() + $p.StandardError.ReadToEnd()
            $line = ($out -split "\r?\n")[0]
            Write-Host "[PRESENT] $cmd : $line"
            Add-Content -Path $LogFile -Value "[PRESENT] $cmd : $line"
            return $true
        }
    } catch {
        Write-Host "[MISSING] $cmd ($($_.Exception.Message))"
        Add-Content -Path $LogFile -Value "[MISSING] $cmd ($($_.Exception.Message))"
        return $false
    }
    return $false
}

Write-Host "=== EXECUTING TOOLCHAIN VERIFICATION CHECKS ==="

$cmds = @(
    @{ cmd = "java"; arg = "-version" },
    @{ cmd = "javac"; arg = "-version" },
    @{ cmd = "rustc"; arg = "--version" },
    @{ cmd = "cargo"; arg = "--version" },
    @{ cmd = "rustup"; arg = "--version" },
    @{ cmd = "flutter"; arg = "--version" },
    @{ cmd = "dart"; arg = "--version" },
    @{ cmd = "sdkmanager"; arg = "--version" },
    @{ cmd = "adb"; arg = "version" },
    @{ cmd = "emulator"; arg = "-version" },
    @{ cmd = "cmake"; arg = "--version" },
    @{ cmd = "ninja"; arg = "--version" }
)

foreach ($c in $cmds) {
    Test-Binary $c.cmd $c.arg
}

Write-Host "Verification checks completed."
