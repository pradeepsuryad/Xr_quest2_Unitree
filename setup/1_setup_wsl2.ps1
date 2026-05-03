# Step 1: WSL2 configuration for Unitree XR Teleoperate
# Run in PowerShell as Administrator.

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "=== Unitree XR Teleoperate - WSL2 Setup ===" -ForegroundColor Cyan

# --- Write .wslconfig (mirrored networking lets Quest 2 reach WSL2 directly) ---
$wslConfigPath = Join-Path $env:USERPROFILE ".wslconfig"
Write-Host "Writing $wslConfigPath ..." -ForegroundColor Yellow

$lines = @(
    "[wsl2]",
    "networkingMode=mirrored",
    "firewall=false",
    "guiApplications=true",
    "memory=8GB",
    "processors=4"
)
$lines | Set-Content -Path $wslConfigPath -Encoding utf8
Write-Host ".wslconfig written - OK" -ForegroundColor Green

# --- Firewall: open port 8012 (televuer HTTPS server for Quest 2) ---
$ruleName = "Unitree XR Teleoperate HTTPS 8012"
$existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if (-not $existing) {
    Write-Host "Adding firewall rule for port 8012 ..." -ForegroundColor Yellow
    New-NetFirewallRule `
        -DisplayName $ruleName `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 8012 `
        -Action Allow `
        -Profile Any | Out-Null
    Write-Host "Firewall rule added - OK" -ForegroundColor Green
} else {
    Write-Host "Firewall rule already exists - OK" -ForegroundColor Green
}

# --- Restart WSL to apply new .wslconfig ---
Write-Host "Shutting down WSL to apply networking config ..." -ForegroundColor Yellow
wsl --shutdown

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next: open Ubuntu from the Start menu (or Windows Terminal)."
Write-Host "If this is your first time, Ubuntu will ask you to create a username and password."
Write-Host ""
Write-Host "Then inside Ubuntu run:"
Write-Host "  bash /mnt/c/Users/dprad/Downloads/Xr_quest2_Unitree/setup/2_install_deps.sh" -ForegroundColor Cyan

