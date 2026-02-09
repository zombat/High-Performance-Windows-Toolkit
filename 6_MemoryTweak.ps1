<#
.SYNOPSIS
    Optimizes Windows Memory Management for Background Services (Docker, WSL, Compiling).
.DESCRIPTION
    1. Checks installed RAM.
    2. Enables "Large System Cache" (Server Mode) if RAM is sufficient.
       - Keeps file operations in RAM longer (Great for compiling/IO).
    3. Adjusts CPU Priority to favor Background Services (prevents Docker throttling).
    
    WARNING: Not recommended for systems with < 16GB RAM.
#>

Write-Host "=== WINDOWS SERVER MEMORY TUNER ===" -ForegroundColor Cyan

# 1. CHECK PHYSICAL MEMORY
$MemObj = Get-CimInstance Win32_ComputerSystem
$RAM_GB = [math]::Round($MemObj.TotalPhysicalMemory / 1GB)

Write-Host "Detected RAM: $RAM_GB GB" -ForegroundColor Yellow

# 2. DEFINE THRESHOLDS
if ($RAM_GB -lt 16) {
    Write-Host "[CRITICAL] You have less than 16GB of RAM." -ForegroundColor Red
    Write-Host "Enabling Large System Cache will likely cause stuttering/swapping."
    $Confirm = Read-Host "Are you absolutely sure you want to proceed? (Type 'FORCE' to override)"
    if ($Confirm -ne "FORCE") {
        Write-Host "Aborted for safety." -ForegroundColor Gray
        exit
    }
} elseif ($RAM_GB -lt 32) {
    Write-Host "[WARN] You have between 16GB-32GB RAM." -ForegroundColor Yellow
    Write-Host "This tweak is safe, but monitor your RAM usage during gaming."
    $Confirm = Read-Host "Proceed? (Y/N)"
    if ($Confirm -ne "Y") { exit }
} else {
    Write-Host "[PASS] 32GB+ RAM detected. Safe to apply Server optimizations." -ForegroundColor Green
}

# 3. APPLY TWEAKS
$MemKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$PriKey = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"

# Toggle Logic: Check if already enabled
$CurrentState = Get-ItemProperty -Path $MemKey -Name "LargeSystemCache" -ErrorAction SilentlyContinue

if ($CurrentState.LargeSystemCache -eq 1) {
    Write-Host "`nServer Mode is currently: ENABLED." -ForegroundColor Green
    $Choice = Read-Host "Do you want to DISABLE it and return to Desktop Mode? (Y/N)"
    if ($Choice -eq "Y") {
        Set-ItemProperty -Path $MemKey -Name "LargeSystemCache" -Value 0
        Set-ItemProperty -Path $PriKey -Name "Win32PrioritySeparation" -Value 2 # Default Desktop (0x26 equivalent usually, or 2 for variable)
        Write-Host "[DONE] Reverted to Standard Desktop Mode. Reboot required." -ForegroundColor Cyan
    }
} else {
    Write-Host "`nServer Mode is currently: DISABLED." -ForegroundColor Yellow
    Write-Host "Applying 'Large System Cache' and 'Background Priority'..."
    
    # A. Large System Cache (0 = Desktop, 1 = Server/File Cache Priority)
    Set-ItemProperty -Path $MemKey -Name "LargeSystemCache" -Value 1 -Type DWORD
    
    # B. CPU Priority (24 decimal = 0x18 hex)
    # 0x18 = Fixed Intervals, Long Quantum, Equal Priority (Best for Background/Services)
    # Standard Desktop is usually 0x26 (Variable, Short, Foreground Boost)
    Set-ItemProperty -Path $PriKey -Name "Win32PrioritySeparation" -Value 24 -Type DWORD
    
    Write-Host "[DONE] Server Memory optimizations applied." -ForegroundColor Green
    Write-Host "Please Reboot for memory manager to switch modes." -ForegroundColor Gray
}

Write-Host "`nPress Enter to exit..."
Read-Host