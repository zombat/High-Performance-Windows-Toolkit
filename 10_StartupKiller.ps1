<#
.SYNOPSIS
    Interactively disables startup programs to speed up boot time.
.DESCRIPTION
    1. Scans Registry (HKCU/HKLM) and Startup Folder.
    2. Filters out critical Windows drivers (Realtek Audio, SecurityHealth).
    3. Asks user for each entry: "Keep or Kill?"
    4. Removes the entry if confirmed.
#>

Write-Host "=== WINDOWS STARTUP KILLER ===" -ForegroundColor Cyan
Write-Host "Scanning for auto-start applications..." -ForegroundColor Yellow

# --- 1. DEFINE LOCATIONS ---
$RegHKCU = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$RegHKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$Folder  = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$DisabledFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup_Disabled"

# --- 2. WHITELIST (CRITICAL STUFF) ---
$Whitelist = @(
    "SecurityHealth", # Windows Defender
    "RTHDVCPL",       # Realtek Audio
    "ETDAniConf",     # Touchpad Driver
    "IgfxTray",       # Intel Graphics
    "OneDrive"        # Optional, but many people panic if it vanishes
)

# --- FUNCTION: PROCESS REGISTRY ---
function Process-RegistryKeys {
    param ($Path, $HiveName)
    
    if (Test-Path $Path) {
        $Keys = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
        # Exclude default properties
        $Names = $Keys.PSObject.Properties.Name | Where-Object { $_ -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider") }

        foreach ($Name in $Names) {
            $Value = $Keys.$Name
            
            # Check Whitelist
            if ($Whitelist -contains $Name) {
                Write-Host "  [SKIP] $Name (System Critical)" -ForegroundColor DarkGray
                continue
            }

            # Ask User
            Write-Host "`nFound in ${HiveName}: " -NoNewline
            Write-Host "'$Name'" -ForegroundColor Cyan
            Write-Host "   Command: $Value" -ForegroundColor Gray
            
            $Choice = Read-Host "   Kill this? (y/N)"
            
            if ($Choice -eq "y") {
                Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
                Write-Host "   [KILLED] Removed from startup." -ForegroundColor Red
            } else {
                Write-Host "   [KEPT] Still running." -ForegroundColor Green
            }
        }
    }
}

# --- FUNCTION: PROCESS FOLDER ---
function Process-StartupFolder {
    if (Test-Path $Folder) {
        $Files = Get-ChildItem -Path $Folder -Filter "*.lnk"
        
        foreach ($File in $Files) {
            Write-Host "`nFound in Startup Folder: " -NoNewline
            Write-Host "'$($File.Name)'" -ForegroundColor Cyan
            
            $Choice = Read-Host "   Kill this? (y/N)"
            
            if ($Choice -eq "y") {
                if (-not (Test-Path $DisabledFolder)) { New-Item -Path $DisabledFolder -ItemType Directory -Force | Out-Null }
                Move-Item -Path $File.FullName -Destination "$DisabledFolder\$($File.Name)" -Force
                Write-Host "   [MOVED] Moved to 'Startup_Disabled' folder." -ForegroundColor Red
            } else {
                Write-Host "   [KEPT] Still running." -ForegroundColor Green
            }
        }
    }
}

# --- 3. EXECUTE ---
Write-Host "`n--- Checking Current User Registry ---"
Process-RegistryKeys $RegHKCU "HKCU"

Write-Host "`n--- Checking Local Machine Registry ---"
Process-RegistryKeys $RegHKLM "HKLM"

Write-Host "`n--- Checking Startup Folder ---"
Process-StartupFolder

Write-Host "`n[DONE] Startup Scan Complete. Reboot to see the speed boost." -ForegroundColor Cyan
Write-Host "Press Enter to exit..."
Read-Host