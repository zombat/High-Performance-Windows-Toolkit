<#
.SYNOPSIS
    Disables Spectre/Meltdown CPU Mitigations.
.DESCRIPTION
    WARNING: THIS REDUCES SYSTEM SECURITY.
    
    It disables the software patches for CPU side-channel attacks.
    - Gain: ~5-15% CPU performance (faster syscalls).
    - Cost: Vulnerability to malicious browser scripts/code.
    
    ONLY run this if you are on a secured, firewalled network and know exactly what you are doing.
    Or, better yet, DON'T RUN THIS!
#>

Write-Host "=== CPU MITIGATION DISABLE (THE 'KAMIKAZE' TWEAK) ===" -ForegroundColor Red
Write-Host "This script disables Windows security patches for Spectre & Meltdown."
Write-Host "You will gain raw CPU speed (syscalls), but your kernel will be vulnerable."
Write-Host "Do NOT do this if you visit random websites or download untrusted code.`n" -ForegroundColor Yellow

$Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

# Check current state
$Current = Get-ItemProperty -Path $Key -Name "FeatureSettingsOverride" -ErrorAction SilentlyContinue

if ($Current.FeatureSettingsOverride -eq 3) {
    Write-Host "Mitigations are currently: DISABLED (Fast/Insecure)." -ForegroundColor Green
    $Choice = Read-Host "Do you want to RE-ENABLE security? (Y/N)"
    if ($Choice -eq "Y") {
        Remove-ItemProperty -Path $Key -Name "FeatureSettingsOverride" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $Key -Name "FeatureSettingsOverrideMask" -ErrorAction SilentlyContinue
        Write-Host "Security restored. Reboot required." -ForegroundColor Cyan
    }
} else {
    Write-Host "Mitigations are currently: ENABLED (Default/Secure)." -ForegroundColor Yellow
    Write-Host "To proceed, you must acknowledge the risk."
    $Confirm = Read-Host "Type 'I AM INSANE' to disable security protections"
    
    if ($Confirm -eq "I AM INSANE") {
        New-ItemProperty -Path $Key -Name "FeatureSettingsOverride" -Value 3 -PropertyType DWORD -Force | Out-Null
        New-ItemProperty -Path $Key -Name "FeatureSettingsOverrideMask" -Value 3 -PropertyType DWORD -Force | Out-Null
        Write-Host "`n[DONE] Mitigations Disabled." -ForegroundColor Red
        Write-Host "Reboot your PC. Your CPU is now running naked." -ForegroundColor Gray
    } else {
        Write-Host "Aborted. Wise choice." -ForegroundColor Green
    }
}

Write-Host "`nPress Enter to exit..."
Read-Host