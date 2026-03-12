<#
.SYNOPSIS
    Unlocks the "Native NVMe" Driver Stack (Server 2025) on Windows 11.
.DESCRIPTION
    Enables hidden "FeatureManagement" flags that bypass the legacy SCSI-translation 
    layer for NVMe drives. This can increase IOPS by ~20% and lower CPU usage.
    
    WARNING: This may break manufacturer tools like Samsung Magician or WD Dashboard.
    RUN AGAIN TO DISABLE/ROLLBACK.
#>

Write-Host "=== WINDOWS 11 NATIVE NVME UNLOCKER ===" -ForegroundColor Cyan
Write-Host "WARNING: This is an experimental tweak from Windows Server 2025." -ForegroundColor Yellow
Write-Host "It may break 'Samsung Magician' or other drive dashboards."
Write-Host "If your system becomes unstable, run this script again to revert.`n" -ForegroundColor Gray

$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides"
$Values  = @("735209102", "1853569164", "156965516")

# Check if keys already exist to determine toggle state
$Exists = Get-ItemProperty -Path $RegPath -Name $Values[0] -ErrorAction SilentlyContinue

if ($Exists) {
    # --- ROLLBACK MODE ---
    Write-Host "Native NVMe is currently: ENABLED." -ForegroundColor Green
    $Choice = Read-Host "Do you want to DISABLE it and revert to stock? (Y/N)"
    if ($Choice -eq "Y") {
        foreach ($Val in $Values) {
            Remove-ItemProperty -Path $RegPath -Name $Val -ErrorAction SilentlyContinue
        }
        Write-Host "`n[SUCCESS] Reverted to stock drivers. Please Reboot." -ForegroundColor Cyan
    }
} else {
    # --- ENABLE MODE ---
    Write-Host "Native NVMe is currently: DISABLED (Default)." -ForegroundColor Yellow
    $Choice = Read-Host "Do you want to ENABLE the Server 2025 driver path? (Y/N)"
    if ($Choice -eq "Y") {
        if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
        
        foreach ($Val in $Values) {
            New-ItemProperty -Path $RegPath -Name $Val -Value 1 -PropertyType DWORD -Force | Out-Null
        }
        Write-Host "`n[SUCCESS] Native NVMe flags injected." -ForegroundColor Green
        Write-Host "1. Reboot your PC."
        Write-Host "2. Check Device Manager -> Storage Controllers."
        Write-Host "3. If you see 'Standard NVM Express Controller', you are good."
        Write-Host "   (Your drive may move from 'Disk Drives' to 'Storage Devices')." -ForegroundColor Gray
    }
}

Write-Host "`nPress Enter to exit..."
Read-Host