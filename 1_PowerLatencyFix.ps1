<#
.SYNOPSIS
    Unlocks "Ultimate Performance" mode and kills Micro-Stutter.
.DESCRIPTION
    1. Checks if "Ultimate Performance" exists (by Name or GUID).
    2. If missing, attempts to enable it.
    3. Falls back to "High Performance" if Ultimate is unavailable.
    4. Reconstructs missing registry keys for PCIe and USB power.
    5. Forces those keys to "Always On" (0) to prevent DPC Latency spikes.
#>

Write-Host "=== ULTIMATE PERFORMANCE & LATENCY UNLOCKER ===" -ForegroundColor Cyan

# --- 1. ROBUST PLAN DETECTION ---
$UltGUID  = "e9a42b02-d5df-448d-aa00-03f14749eb61"
$HighGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"

# Try to find Ultimate by GUID or Name
$Plan = Get-CimInstance -ClassName Win32_PowerPlan -Namespace root\cimv2\power | 
    Where-Object { $_.InstanceID -match $UltGUID -or $_.ElementName -eq "Ultimate Performance" } | 
    Select-Object -First 1

# If not found, try to create it
if (-not $Plan) {
    Write-Host "Ultimate Performance not found. Attempting to unlock..." -ForegroundColor Yellow
    powercfg -duplicatescheme $UltGUID | Out-Null
    # Refetch
    $Plan = Get-CimInstance -ClassName Win32_PowerPlan -Namespace root\cimv2\power | 
        Where-Object { $_.InstanceID -match $UltGUID -or $_.ElementName -eq "Ultimate Performance" } | 
        Select-Object -First 1
}

# If STILL not found (e.g. Windows Home restrictions), fallback to High Performance
if (-not $Plan) {
    Write-Host "[WARN] Ultimate Performance blocked by OS. Falling back to High Performance." -ForegroundColor Yellow
    $Plan = Get-CimInstance -ClassName Win32_PowerPlan -Namespace root\cimv2\power | 
        Where-Object { $_.InstanceID -match $HighGUID } | 
        Select-Object -First 1
}

# Activate the best available plan
if ($Plan) {
    # FIX: Extract the naked GUID from the CIM format "Microsoft:PowerPlan\{GUID}"
    $CleanGUID = $Plan.InstanceID -replace ".*\{|\}.*", ""
    
    Write-Host "Switching Active Plan to: $($Plan.ElementName)" -ForegroundColor Green
    powercfg -setactive $CleanGUID
} else {
    Write-Host "[ERROR] Could not set a performance plan. Registry patches may not apply correctly." -ForegroundColor Red
}

# --- 2. REGISTRY LATENCY PATCHES ---
# Get the actual Active Plan GUID (in case the switch above failed)
$ActivePlan = Get-CimInstance -ClassName Win32_PowerPlan -Namespace root\cimv2\power | Where-Object { $_.IsActive } | Select-Object -ExpandProperty InstanceID
$PlanGUID = $ActivePlan -replace ".*\{|\}.*", ""

$PowerBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings"
$PCIe_Sub  = "501a4d13-42af-4429-9fd1-a8218c268e20" # PCIe Subgroup
$PCIe_Set  = "ee12f906-d277-404b-b6da-e5fa1a576df5" # Link State Setting
$USB_Sub   = "2a737441-1930-4402-8d77-b94982725347" # USB Subgroup
$USB_Set   = "48e6b7a6-50f5-4782-a5d4-53bb8f07e226" # Selective Suspend Setting

function Force-RegFix {
    param ($Sub, $Set, $Name)
    $RegPath = "$PowerBase\$Sub\$Set"
    
    # Unhide the setting if OEM deleted it
    if (-not (Test-Path $RegPath)) {
        New-Item -Path "$PowerBase\$Sub" -Name $Set -Force | Out-Null
    }
    Set-ItemProperty -Path $RegPath -Name "Attributes" -Value 0 -Force
    
    # Force Setting to 0 (OFF) for the Active Plan
    $PlanPath = "$RegPath\DefaultPowerSchemeValues\$PlanGUID"
    if (-not (Test-Path $PlanPath)) {
        New-Item -Path "$RegPath\DefaultPowerSchemeValues" -Name $PlanGUID -Force | Out-Null
    }
    Set-ItemProperty -Path $PlanPath -Name "ACSettingIndex" -Value 0 -Type DWORD -Force
    Set-ItemProperty -Path $PlanPath -Name "DCSettingIndex" -Value 0 -Type DWORD -Force
    Write-Host "  [FIXED] $Name forced to 'Always On' (Latency Free)." -ForegroundColor Green
}

Force-RegFix $PCIe_Sub $PCIe_Set "PCIe Link State"
Force-RegFix $USB_Sub $USB_Set "USB Selective Suspend"

# --- 3. DISABLE USB PnP SLEEP (The "Nuclear Option") ---
Write-Host "  [FIXED] Disabling Individual USB Hub Sleep..." -ForegroundColor Green
Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\USB" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.Property -contains "Device Parameters") {
        $path = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\$($_.PSChildName)\Device Parameters"
        New-ItemProperty -Path $path -Name "DeviceSelectiveSuspended" -Value 0 -PropertyType DWORD -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $path -Name "SelectiveSuspendEnabled" -Value 0 -PropertyType DWORD -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

Write-Host "`n[DONE] Power Plan & Latency Optimizations Applied." -ForegroundColor Cyan