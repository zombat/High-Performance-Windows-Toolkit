<#
.SYNOPSIS
    Surgically removes Windows 11 bloatware with User Consent.
.DESCRIPTION
    1. DISABLES COPILOT (The AI Sidebar).
    2. Disables Telemetry & Bing Search.
    3. Scans for bloatware (Candy Crush, Disney+, etc.) and asks before removing.
    4. Protects Developer Tools (WSL, Terminal, Winget).
#>

Write-Host "=== WINDOWS INTERACTIVE DEBLOATER ===" -ForegroundColor Cyan
Write-Host "Safely remove junk while protecting Developer Tools." -ForegroundColor Yellow
Write-Host "You will be asked to confirm each major action.`n" -ForegroundColor Gray

# --- 1. THE COPILOT KILLER ---
$KillCopilot = Read-Host "Do you want to DISABLE Windows Copilot (The AI Sidebar)? (y/N)"
if ($KillCopilot -eq "y") {
    Write-Host "  Disabling Copilot Policy..." -NoNewline
    $CopilotKey = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
    if (-not (Test-Path $CopilotKey)) { New-Item -Path $CopilotKey -Force | Out-Null }
    Set-ItemProperty -Path $CopilotKey -Name "TurnOffWindowsCopilot" -Value 1 -Type DWORD -Force
    
    # Also kill the Taskbar button
    $TaskbarKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $TaskbarKey -Name "ShowCopilotButton" -Value 0 -Type DWORD -Force -ErrorAction SilentlyContinue
    
    Write-Host " DONE." -ForegroundColor Green
}

# --- 2. TELEMETRY & ADS ---
$KillTelem = Read-Host "`nDo you want to disable Telemetry & Start Menu Ads? (y/N)"
if ($KillTelem -eq "y") {
    # DiagTrack
    Stop-Service "DiagTrack" -ErrorAction SilentlyContinue
    Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    
    # Bing Search in Start
    $ExplorerPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
    if (-not (Test-Path $ExplorerPath)) { New-Item -Path $ExplorerPath -Force | Out-Null }
    Set-ItemProperty -Path $ExplorerPath -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWORD -Force
    
    # Lock Screen Ads
    $ContentPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    if (Test-Path $ContentPath) {
        Set-ItemProperty -Path $ContentPath -Name "RotatingLockScreenEnabled" -Value 0 -Type DWORD -Force
        Set-ItemProperty -Path $ContentPath -Name "SubscribedContent-338387Enabled" -Value 0 -Type DWORD -Force
    }
    
    Write-Host "  [FIX] Telemetry & Ads disabled." -ForegroundColor Green
}

# --- 3. APP REMOVAL LOOP ---
Write-Host "`nScanning for installed Bloatware..." -ForegroundColor Yellow

# The Hit List
$BloatPatterns = @(
    "*BingNews*", "*BingWeather*", "*Clipchamp*", "*Disney*", "*Facebook*", 
    "*GetHelp*", "*GetStarted*", "*MicrosoftOfficeHub*", "*Solitaire*", 
    "*Netflix*", "*News*", "*People*", "*PowerAutomate*", "*Skype*", 
    "*Spotify*", "*TikTok*", "*Todos*", "*Twitter*", "*Xbox*", "*YourPhone*", 
    "*ZuneMusic*", "*ZuneVideo*"
)

# The Whitelist (System Critical)
$Whitelist = @(
    "*WindowsTerminal*", "*WindowsStore*", "*Calculator*", "*ScreenSketch*", 
    "*SecHealthUI*", "*VCLibs*", "*DesktopAppInstaller*", "*WindowsSubsystemForLinux*"
)

$FoundApps = Get-AppxPackage | Where-Object { 
    $Name = $_.Name
    $IsBloat = $BloatPatterns | Where-Object { $Name -like $_ }
    $IsSafe  = $Whitelist | Where-Object { $Name -like $_ }
    return $IsBloat -and (-not $IsSafe)
}

if ($FoundApps.Count -eq 0) {
    Write-Host "  [PASS] No common bloatware found." -ForegroundColor Green
} else {
    foreach ($App in $FoundApps) {
        $UserChoice = Read-Host "Found '$($App.Name)'. Remove? (y/N)"
        if ($UserChoice -eq "y") {
            Write-Host "  Removing $($App.Name)..." -NoNewline
            $App | Remove-AppxPackage -ErrorAction SilentlyContinue
            Write-Host " GONE." -ForegroundColor Red
        } else {
            Write-Host "  Skipped." -ForegroundColor Gray
        }
    }
}

Write-Host "`n[DONE] Debloat Complete. Reboot recommended." -ForegroundColor Cyan
Write-Host "Press Enter to exit..."
Read-Host