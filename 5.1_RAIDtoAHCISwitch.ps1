<#
.SYNOPSIS
    Detects Intel RST / RAID mode and guides you through a safe AHCI switch.
.DESCRIPTION
    1. Checks if physical disks are running under Intel RST / RAID mode.
    2. If RAID is detected, prints the exact procedure to safely switch to AHCI
       without triggering an INACCESSIBLE_BOOT_DEVICE blue screen.

    GUIDANCE ONLY: This script makes no automated system changes.
    You execute each step yourself, in sequence.

    RISK: HIGH if steps are skipped. The Safe Mode boot is mandatory —
    it installs AHCI drivers before the full OS loads. Skipping it WILL blue screen.

    Back up all critical data before proceeding.
#>

Write-Host "=== RAID MODE DETECTOR & SAFE AHCI SWITCH GUIDE ===" -ForegroundColor Cyan

$raidDrives = Get-PhysicalDisk | Where-Object { $_.BusType -eq 'RAID' }

if ($null -ne $raidDrives -and $raidDrives.Count -gt 0) {
    Write-Warning "Intel RST / RAID mode detected. Windows is blind to raw PCIe lane data."
    Write-Host "`nStep 1: Open Command Prompt (Admin) and run: bcdedit /set {current} safeboot minimal" -ForegroundColor Yellow
    Write-Host "Step 2: Restart PC, enter BIOS, and change Storage Mode from 'RAID' to 'AHCI/NVMe'."
    Write-Host "Step 3: Let Windows boot into Safe Mode (this installs the drivers)."
    Write-Host "Step 4: Open Command Prompt (Admin) and run: bcdedit /deletevalue {current} safeboot" -ForegroundColor Yellow
    Write-Host "Step 5: Restart normally. You can now read your PCIe lanes."
}

Write-Host "`nPress Enter to exit..."
Read-Host

