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

# --- Hyper-V firewall rule: allow inbound 8012 to WSL VM (mirrored mode) ---
# Without this, devices on the LAN (like Quest 2) cannot reach WSL2 services
# even if the regular Windows firewall allows the port.
$wslVmId = "{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}"
$hvRuleName = "WSL-Port-8012-Inbound"
try {
    $hvExisting = Get-NetFirewallHyperVRule -Name $hvRuleName -ErrorAction SilentlyContinue
    if (-not $hvExisting) {
        Write-Host "Adding Hyper-V firewall rule for WSL port 8012 ..." -ForegroundColor Yellow
        New-NetFirewallHyperVRule `
            -Name $hvRuleName `
            -DisplayName "WSL Port 8012 Inbound (Quest XR)" `
            -VMCreatorId $wslVmId `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPorts 8012 `
            -Action Allow | Out-Null
        Write-Host "Hyper-V firewall rule added - OK" -ForegroundColor Green
    } else {
        Write-Host "Hyper-V firewall rule already exists - OK" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not configure Hyper-V firewall rule: $_" -ForegroundColor Yellow
    Write-Host "(This may not be needed if firewall=false in .wslconfig is honored)" -ForegroundColor Yellow
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

