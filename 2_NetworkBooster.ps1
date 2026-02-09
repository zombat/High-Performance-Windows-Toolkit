<#
.SYNOPSIS
    Interactively disables vendor-specific "Optimizer" services.
.DESCRIPTION
    1. Scans for known bloatware from Dell, HP, ASUS, MSI, Razer, Corsair, and Logitech.
    2. Displays the Service Name and Description.
    3. Asks the user: "Disable this? (y/N)" for each found service.
    
    TARGETS: "Game Optimizers", "Analytics", and "Support Assistants" that cause DPC Latency.
#>

Write-Host "=== INTERACTIVE BLOATWARE NEUTRALIZER ===" -ForegroundColor Cyan
Write-Host "Scanning for vendor-specific background services..." -ForegroundColor Yellow

# The "Hit List" of known bad services
$BloatServices = @(
    # Dell / Alienware
    "Killer Analytics Service", "Killer Network Service", "KNDBWM", 
    "Dell SupportAssist", "Dell Data Vault Collector", "DellClientManagementService", 
    "DDVDataCollector", "DDVRulesProcessor",
    
    # ASUS
    "ArmouryCrateService", "AsusROGLSLService", "AsusFanControlService", 
    "AsusAppService", "AsusLinkNear", "AsusLinkRemote",
    
    # MSI
    "Dragon Center Service", "Mystic Light", "NTIOLib_1_0_C", "MSI_Central_Service",
    
    # HP
    "HP Omen Command Center", "HP App Helper", "HP Network HSM Service", 
    "HPAnalyticsService", "HPSysInfoCap",
    
    # Razer / Corsair / Logitech
    "Razer Synapse Service", "RzKLService", "Razer Central Service", 
    "CorsairLLAService", "CorsairMsiPlugin",
    "Lghub_updater", "LGS"
)

$FoundCount = 0

foreach ($srvName in $BloatServices) {
    # Check if service exists
    $srv = Get-Service -Name $srvName -ErrorAction SilentlyContinue
    
    if ($srv) {
        $FoundCount++
        $Status = $srv.Status
        $Color  = if ($Status -eq "Running") { "Red" } else { "Gray" }
        
        Write-Host "`nFound: " -NoNewline
        Write-Host "$($srv.DisplayName) " -NoNewline -ForegroundColor Cyan
        Write-Host "($($srv.Name))" -ForegroundColor Gray
        Write-Host "   State: " -NoNewline
        Write-Host "$Status" -ForegroundColor $Color
        
        # If it's already disabled, skip asking
        if ($srv.StartType -eq "Disabled") {
            Write-Host "   [INFO] Already Disabled." -ForegroundColor Green
            continue
        }

        $Choice = Read-Host "   Disable this service? (y/N)"
        
        if ($Choice -eq "y") {
            # Stop it
            if ($srv.Status -eq "Running") {
                Write-Host "   Stopping..." -NoNewline
                Stop-Service -Name $srvName -Force -ErrorAction SilentlyContinue
                Write-Host " DONE." -ForegroundColor Green
            }
            
            # Disable it
            Write-Host "   Disabling Startup..." -NoNewline
            Set-Service -Name $srvName -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host " DONE." -ForegroundColor Green
        } else {
            Write-Host "   [SKIPPED] Service left active." -ForegroundColor Gray
        }
    }
}

if ($FoundCount -eq 0) {
    Write-Host "`n[PASS] No known bloatware services found on this machine." -ForegroundColor Green
} else {
    Write-Host "`n[DONE] Scan Complete." -ForegroundColor Cyan
}

Write-Host "Press Enter to exit..."
Read-Host