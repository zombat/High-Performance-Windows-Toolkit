<#
.SYNOPSIS
    Checks current vs. maximum PCIe lane configuration for all display adapters.
.DESCRIPTION
    Queries the Windows Plug and Play (PnP) manager to display the current and
    maximum PCIe generation and lane width for each connected GPU.

    READ-ONLY: This script makes no changes to your system.

    IMPORTANT: Modern GPUs aggressively downclock their PCIe generation when
    idling on the desktop to save power (e.g., a Gen 4 card may report Gen 1
    or Gen 3 at idle). For accurate maximum-speed readings, run this script
    while the GPU is under graphical load (gaming, rendering, stress test).
#>

Write-Host "=== GPU PCIE LANE CHECKER ===" -ForegroundColor Cyan
Write-Host "Read-only diagnostic. No changes will be made.`n" -ForegroundColor Gray

Write-Host "[NOTE] GPU PCIe power management:" -ForegroundColor Yellow
Write-Host "  Modern GPUs drop to Gen 1/2/3 while idling to save power." -ForegroundColor Gray
Write-Host "  For accurate maximum-speed readings, run this script under GPU load" -ForegroundColor Gray
Write-Host "  (gaming, a renderer, or a stress tool like FurMark or 3DMark).`n" -ForegroundColor Gray

# --- QUERY DISPLAY ADAPTERS VIA PNP ---
# Query connected Display adapters
Get-PnpDevice -Class Display -PresentOnly | Where-Object { $_.InstanceId -match "^PCI\\" } | ForEach-Object {
    $instanceId = $_.InstanceId

    $currentWidth    = (Get-PnpDeviceProperty -InstanceId $instanceId -KeyName 'DEVPKEY_PciDevice_CurrentLinkWidth' -ErrorAction SilentlyContinue).Data
    $maxWidth        = (Get-PnpDeviceProperty -InstanceId $instanceId -KeyName 'DEVPKEY_PciDevice_MaxLinkWidth' -ErrorAction SilentlyContinue).Data
    $currentSpeedVal = (Get-PnpDeviceProperty -InstanceId $instanceId -KeyName 'DEVPKEY_PciDevice_CurrentLinkSpeed' -ErrorAction SilentlyContinue).Data
    $maxSpeedVal     = (Get-PnpDeviceProperty -InstanceId $instanceId -KeyName 'DEVPKEY_PciDevice_MaxLinkSpeed' -ErrorAction SilentlyContinue).Data

    $speedMap = @{ 1 = "Gen 1"; 2 = "Gen 2"; 3 = "Gen 3"; 4 = "Gen 4"; 5 = "Gen 5" }

    [PSCustomObject]@{
        GPU          = $_.FriendlyName
        CurrentLanes = if ($currentWidth) { "x$currentWidth" } else { "N/A" }
        MaxLanes     = if ($maxWidth) { "x$maxWidth" } else { "N/A" }
        CurrentSpeed = if ($null -ne $currentSpeedVal -and $speedMap.ContainsKey([int]$currentSpeedVal)) { $speedMap[[int]$currentSpeedVal] } else { "N/A" }
        MaxSpeed     = if ($null -ne $maxSpeedVal -and $speedMap.ContainsKey([int]$maxSpeedVal)) { $speedMap[[int]$maxSpeedVal] } else { "N/A" }
    }
} | Format-Table -AutoSize

Write-Host "`nPress Enter to exit..."
Read-Host
