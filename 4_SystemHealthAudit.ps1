<#
.SYNOPSIS
    Audits System Health: Failed Hardware, Old Drivers, and File Integrity.
#>

Write-Host "=== SYSTEM HEALTH AUDIT ===" -ForegroundColor Cyan

# 1. GHOST DEVICES
Write-Host "`n[1] Scanning for Hardware Errors..." -ForegroundColor Yellow
$failed = Get-PnpDevice | Where-Object { $_.Status -eq "Error" -or $_.Status -eq "Degraded" }
if ($failed) {
    foreach ($dev in $failed) {
        Write-Host "  [FAIL] $($dev.FriendlyName) (Code: $($dev.Problem))" -ForegroundColor Red
        if ($dev.FriendlyName -match "XTU Component") { Write-Host "    -> FIX: Uninstall Intel Extreme Tuning Utility (Incompatible)." -ForegroundColor Gray }
        if ($dev.FriendlyName -match "Port Reset Failed") { Write-Host "    -> FIX: Power Cycle required (Unplug + Hold Power Button 30s)." -ForegroundColor Gray }
    }
} else {
    Write-Host "  [PASS] No hardware errors detected." -ForegroundColor Green
}

# 2. DRIVER AGE CHECK
Write-Host "`n[2] Checking Driver Freshness..." -ForegroundColor Yellow
$driverList = Get-CimInstance Win32_PnPSignedDriver | Where-Object { 
    $_.DeviceName -match "NVIDIA|GeForce|Radeon|Intel|Realtek|Killer|Broadcom" -and 
    $_.DeviceName -notmatch "USB|Audio|Bluetooth|Volume|System"
}

foreach ($drv in $driverList) {
    $date = $null
    if ($drv.DriverDate -is [DateTime]) { $date = $drv.DriverDate } 
    elseif ($drv.DriverDate -match "^\d{8}") { try { $date = [DateTime]::ParseExact($drv.DriverDate.Substring(0, 8), "yyyyMMdd", $null) } catch {} }

    if ($date) {
        $age = (Get-Date) - $date
        # Flag if older than 3 years AND NOT the 1968/2009 placeholder dates
        if ($age.Days -gt 1095 -and $date.Year -gt 2010) { 
            Write-Host "  [WARN] Old Driver: $($drv.DeviceName)" -ForegroundColor Yellow
            Write-Host "         Date: $($date.ToShortDateString())" -ForegroundColor Gray
        }
    }
}

# 3. INTEGRITY CHECK
Write-Host "`n[3] Windows Integrity Check..." -ForegroundColor Yellow
$dism = Dism /Online /Cleanup-Image /CheckHealth
if ($dism -match "No component store corruption detected") {
    Write-Host "  [PASS] System files are healthy." -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Corruption detected. Run 'sfc /scannow'." -ForegroundColor Red
}

Write-Host "`n=== AUDIT COMPLETE ===" -ForegroundColor Cyan