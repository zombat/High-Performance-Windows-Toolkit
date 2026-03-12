<#
.SYNOPSIS
    Checks current vs. maximum PCIe lane configuration for all NVMe controllers.
.DESCRIPTION
    Queries the Windows Plug and Play (PnP) manager to display the current and
    maximum PCIe generation and lane width for each connected NVMe controller.

    READ-ONLY: This script makes no changes to your system.

    NOTE: If your drives show BusType 'RAID' (Intel RST), Windows cannot see
    the raw PCIe lane data underneath the RST abstraction layer.
    Run 5.1_RAIDtoAHCISwitch.ps1 first to safely switch to AHCI mode.
#>

Write-Host "=== NVME PCIE LANE CHECKER ===" -ForegroundColor Cyan
Write-Host "Read-only diagnostic. No changes will be made.`n" -ForegroundColor Gray

# --- CHECK FOR RAID MODE (Intel RST blocks raw PCIe visibility) ---
$raidDrives = Get-PhysicalDisk | Where-Object { $_.BusType -eq 'RAID' }

if ($null -ne $raidDrives -and $raidDrives.Count -gt 0) {
    Write-Host "[WARNING] Intel RST / RAID mode detected." -ForegroundColor Yellow
    Write-Host "          Windows cannot see raw PCIe lane data while RAID mode is active." -ForegroundColor Yellow
    Write-Host "          Run 5.1_RAIDtoAHCISwitch.ps1 to safely switch to AHCI mode first.`n" -ForegroundColor Yellow
}

# --- QUERY NVME CONTROLLERS VIA PNP ---
# Query all connected PCI devices that are NVMe controllers
Get-PnpDevice -PresentOnly | Where-Object {
    $_.InstanceId -match "^PCI\\" -and
    ($_.FriendlyName -match "NVMe" -or $_.FriendlyName -match "NVM Express")
} | ForEach-Object {
    $instanceId = $_.InstanceId

    # Link Width (Lanes)
    $currentWidth = (Get-PnpDeviceProperty -InstanceId $instanceId -KeyName 'DEVPKEY_PciDevice_CurrentLinkWidth' -ErrorAction SilentlyContinue).Data
    $maxWidth     = (Get-PnpDeviceProperty -InstanceId $instanceId -KeyName 'DEVPKEY_PciDevice_MaxLinkWidth' -ErrorAction SilentlyContinue).Data

    # Link Speed (Generation)
    $currentSpeedVal = (Get-PnpDeviceProperty -InstanceId $instanceId -KeyName 'DEVPKEY_PciDevice_CurrentLinkSpeed' -ErrorAction SilentlyContinue).Data
    $maxSpeedVal     = (Get-PnpDeviceProperty -InstanceId $instanceId -KeyName 'DEVPKEY_PciDevice_MaxLinkSpeed' -ErrorAction SilentlyContinue).Data

    $speedMap = @{ 1 = "Gen 1"; 2 = "Gen 2"; 3 = "Gen 3"; 4 = "Gen 4"; 5 = "Gen 5" }

    [PSCustomObject]@{
        Device       = $_.FriendlyName
        CurrentLanes = if ($null -ne $currentWidth) { "x$currentWidth" } else { "N/A" }
        MaxLanes     = if ($null -ne $maxWidth) { "x$maxWidth" } else { "N/A" }
        CurrentSpeed = if ($null -ne $currentSpeedVal -and $speedMap.ContainsKey([int]$currentSpeedVal)) { $speedMap[[int]$currentSpeedVal] } else { "N/A" }
        MaxSpeed     = if ($null -ne $maxSpeedVal -and $speedMap.ContainsKey([int]$maxSpeedVal)) { $speedMap[[int]$maxSpeedVal] } else { "N/A" }
    }
} | Format-Table -AutoSize

Write-Host "`nPress Enter to exit..."
Read-Host
