<#
.SYNOPSIS
    Enables Message Signaled Interrupts (MSI) for capable hardware.
.DESCRIPTION
    1. WARNS USER OF BOOT RISKS.
    2. BYPASSES RESTORE POINT FREQUENCY LIMIT (Force Create).
    3. Offers 3 Modes:
       - [1] INCREMENTAL (Safe)
       - [2] LEEROY JENKINS (Risky)
       - [3] EXIT
    
    BENEFIT: Drastically reduces DPC Latency and interrupt conflicts.
    RISK: Medium. If a driver lies about MSI support, Windows will BSOD.
#>

Clear-Host
Write-Host "=== MSI MODE ENABLER (LATENCY KILLER) ===" -ForegroundColor Cyan

# --- 0. THE WARNING ---
Write-Host "`n[WARNING] READ CAREFULLY" -ForegroundColor Red
Write-Host "This script changes how your hardware talks to the CPU."
Write-Host "If a specific driver (usually Realtek or older SATA) claims to support MSI"
Write-Host "but actually crashes, your PC will hit a BLUE SCREEN on boot."
Write-Host "`nYou MUST know how to boot into Safe Mode or Recovery Environment"
Write-Host "to use the System Restore point we are about to create."
Write-Host "`nPress Ctrl+C to Cancel, or Enter to Proceed..."
Read-Host

# --- 1. SCANNING PHASE ---
Write-Host "Scanning PCI Bus for MSI-Capable Devices..." -ForegroundColor Yellow

$Devices = Get-PnpDevice -Class "Display","Net","SCSIAdapter","USB","HDC" -Status OK | Where-Object { $_.InstanceId -match "^PCI" }
$Candidates = @()

foreach ($Dev in $Devices) {
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($Dev.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
    if (Test-Path $RegPath) {
        $Props = Get-ItemProperty -Path $RegPath -ErrorAction SilentlyContinue
        if ($Props.MSISupported -eq 1 -and $Props.MSIEnabled -ne 1) {
             $Candidates += $Dev
        }
    }
}

if ($Candidates.Count -eq 0) {
    Write-Host "`n[INFO] All capable devices are already using MSI Mode! You are good." -ForegroundColor Green
    Write-Host "Press Enter to exit..."
    Read-Host
    exit
}

# List Candidates
Write-Host "`nFound $($Candidates.Count) device(s) waiting for MSI Mode:" -ForegroundColor Yellow
foreach ($C in $Candidates) {
    Write-Host " - $($C.FriendlyName)" -ForegroundColor Gray
}

# --- 2. CHOOSE YOUR DESTINY ---
Write-Host "`nSelect Mode:" -ForegroundColor Cyan
Write-Host "[1] INCREMENTAL (Safe)" -ForegroundColor Green
Write-Host "    Enables ONE device, creates a Restore Point, and stops so you can reboot."
Write-Host "[2] LEEROY JENKINS (Risky)" -ForegroundColor Red
Write-Host "    Enables ALL devices at once with a single Restore Point."
Write-Host "[3] EXIT" -ForegroundColor Gray

$Mode = Read-Host "`nChoose [1, 2, 3]"

if ($Mode -eq "3") { exit }

# --- 3. SAFETY FIRST: SYSTEM RESTORE ---
Write-Host "`nInitializing Safety Protocols..." -ForegroundColor Yellow

# Helper Function: Bypass the 24-hour limit
function Enable-InstantRestorePoints {
    $RegPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore"
    # Create key if missing
    if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
    # Set Frequency to 0 (Unlimited)
    New-ItemProperty -Path $RegPath -Name "SystemRestorePointCreationFrequency" -Value 0 -PropertyType DWORD -Force | Out-Null
    Write-Host "  [FIX] Registry patched to allow instant Restore Points." -ForegroundColor Gray
}

function Cleanup-RestoreRegistry {
    $RegPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore"
    # Remove the hack so Windows goes back to default behavior
    Remove-ItemProperty -Path $RegPath -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue
}

# Verify Service
try {
    $Test = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
    $CanCreate = $true
} catch {
    $CanCreate = $false
}

if ($CanCreate) {
    try {
        # 1. Bypass Frequency Limit
        Enable-InstantRestorePoints
        
        # 2. Define Name
        $PointName = if ($Mode -eq "1") { "Pre-MSI: $($Candidates[0].FriendlyName)" } else { "Pre-MSI: ALL DEVICES" }
        Write-Host "Creating System Restore Point: '$PointName'..." -NoNewline
        
        # 3. Create Point
        Checkpoint-Computer -Description $PointName -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        
        # 4. Verify Creation (The step we missed last time)
        $Latest = Get-ComputerRestorePoint | Sort-Object CreationTime -Descending | Select-Object -First 1
        if ($Latest.Description -eq $PointName) {
             Write-Host " DONE." -ForegroundColor Green
        } else {
             throw "Verification Failed. The Restore Point was not found."
        }

    } catch {
        Write-Host " FAILED." -ForegroundColor Red
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  [WARN] Failed to create a verifiable Restore Point." -ForegroundColor Yellow
        
        Cleanup-RestoreRegistry
        
        $Choice = Read-Host "  Do you want to proceed WITHOUT a backup? (Type 'RISK' to continue)"
        if ($Choice -ne "RISK") {
            Write-Host "Aborted. Safety checks failed." -ForegroundColor Gray
            exit
        }
    } finally {
        # Clean up the registry hack
        Cleanup-RestoreRegistry
    }
} else {
    Write-Host "  [WARN] System Restore service is unavailable." -ForegroundColor Yellow
    $Choice = Read-Host "  Do you want to proceed without a backup? (Type 'RISK' to continue)"
    if ($Choice -ne "RISK") { exit }
}

# --- 4. EXECUTION ---
if ($Mode -eq "1") {
    # INCREMENTAL
    $Target = $Candidates[0]
    Write-Host "`nEnabling MSI for: $($Target.FriendlyName)..." -NoNewline
    
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($Target.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
    Set-ItemProperty -Path $RegPath -Name "MSIEnabled" -Value 1 -Type DWORD -Force
    
    Write-Host " DONE." -ForegroundColor Green
    Write-Host "`n[Safe Step Complete] Please REBOOT now to verify stability." -ForegroundColor Cyan
    Write-Host "If stable, run this script again to do the next device." -ForegroundColor Gray

} elseif ($Mode -eq "2") {
    # LEEROY JENKINS
    Write-Host "`nLEEROY JENKINS! Doing it live..." -ForegroundColor Red
    
    foreach ($Target in $Candidates) {
        Write-Host "Enabling: $($Target.FriendlyName)..." -NoNewline
        $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($Target.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        Set-ItemProperty -Path $RegPath -Name "MSIEnabled" -Value 1 -Type DWORD -Force
        Write-Host " DONE." -ForegroundColor Green
    }
    
    Write-Host "`n[ALL DONE] Please REBOOT IMMEDIATELY." -ForegroundColor Red
    Write-Host "If Windows fails to boot:" -ForegroundColor Gray
    Write-Host "1. Interrupt boot 3 times to enter Recovery."
    Write-Host "2. Select 'System Restore' and choose '$PointName'."
}

Write-Host "`nPress Enter to exit..."
Read-Host