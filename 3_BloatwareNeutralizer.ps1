<#
.SYNOPSIS
    Disables vendor-specific "Optimizer" services that cause DPC Latency.
.DESCRIPTION
    Targets known bloatware from Dell, HP, ASUS, MSI, Razer, Corsair, and Logitech.
    These services often poll hardware excessively, causing micro-stutters.
#>

Write-Host "=== LATENCY BLOATWARE NEUTRALIZER ===" -ForegroundColor Cyan

$BloatServices = @(
    # Dell / Alienware
    "Killer Analytics Service", "Killer Network Service", "KNDBWM", "Dell SupportAssist", "Dell Data Vault Collector", "DellClientManagementService",
    # ASUS
    "ArmouryCrateService", "AsusROGLSLService", "AsusFanControlService",
    # MSI
    "Dragon Center Service", "Mystic Light", "NTIOLib_1_0_C",
    # HP
    "HP Omen Command Center", "HP App Helper", "HP Network HSM Service",
    # Razer / Corsair / Logitech
    "Razer Synapse Service", "RzKLService", "CorsairLLAService", "Lghub_updater"
)

foreach ($srvName in $BloatServices) {
    $srv = Get-Service -Name $srvName -ErrorAction SilentlyContinue
    if ($srv -and $srv.Status -eq "Running") {
        Write-Host "  [FOUND] $($srv.DisplayName)..." -NoNewline
        Stop-Service -Name $srvName -Force -ErrorAction SilentlyContinue
        Set-Service -Name $srvName -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host " NEUTRALIZED." -ForegroundColor Green
    }
}

Write-Host "`n[DONE] Active background bloatware has been disabled." -ForegroundColor Cyan