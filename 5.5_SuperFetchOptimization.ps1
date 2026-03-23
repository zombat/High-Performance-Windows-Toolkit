<#
.SYNOPSIS
    Optimizes Windows SysMain/Prefetch settings based on system configuration.
.DESCRIPTION
    1. Checks installed RAM and physical disk types (HDD/SSD).
    2. Reads current SysMain/Prefetch mode from registry.
    3. Recommends optimal mode:
       - Mode 2 (Boot only): For systems with HDDs and 16GB+ RAM to prevent background disk thrashing.
       - Mode 3 (Full caching): Default for most other configurations.
    4. Applies the recommended mode and restarts SysMain service.
    
    NOTE: Mode values: 0=Disabled, 1=Apps, 2=Boot, 3=Full (default)
#>

Write-Host "Analyzing SysMain (Superfetch) / Memory Caching..." -ForegroundColor Yellow

$physicalDisks = @(Get-PhysicalDisk)
$hasHDD = ($physicalDisks | Where-Object { $_.MediaType -eq 'HDD' -or $_.MediaType -eq 'Unspecified' }).Count -gt 0
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"

# Read BOTH possible registry values
$sfValue = (Get-ItemProperty -Path $regPath -Name "EnableSuperfetch" -ErrorAction SilentlyContinue).EnableSuperfetch
$pfValue = (Get-ItemProperty -Path $regPath -Name "EnablePrefetcher" -ErrorAction SilentlyContinue).EnablePrefetcher

# Use whichever exists (Superfetch takes priority), fall back to default 3
$currentMode = if ($null -ne $sfValue) { $sfValue }
               elseif ($null -ne $pfValue) { $pfValue }
               else { 3 }

$displayMode = "$currentMode (Source: $(if ($null -ne $sfValue) { 'EnableSuperfetch' } elseif ($null -ne $pfValue) { 'EnablePrefetcher' } else { 'Default/Not Set' }))"

$suggestedMode = if ($hasHDD -and $ramGB -ge 16) { 2 } else { 3 }
$reason = if ($suggestedMode -eq 2) { "HDDs + High RAM: Boot Only recommended to stop background thrashing." } else { "Default caching is appropriate." }

Write-Host "  RAM: $ramGB GB | HDDs Present: $hasHDD" -ForegroundColor White
Write-Host "  Current Mode:  $displayMode" -ForegroundColor Yellow
Write-Host "  Suggested:     Mode $suggestedMode ($reason)" -ForegroundColor Gray

if ($currentMode -ne $suggestedMode) {
    if ((Read-Host "  Apply Mode $suggestedMode and restart SysMain? (y/n)") -eq 'y') {
        try {
            if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force -ErrorAction Stop | Out-Null }
            
            # Writing both keys ensures consistency moving forward
            Set-ItemProperty -Path $regPath -Name "EnableSuperfetch" -Value $suggestedMode -Type DWord -Force -ErrorAction Stop
            Set-ItemProperty -Path $regPath -Name "EnablePrefetcher" -Value $suggestedMode -Type DWord -Force -ErrorAction Stop
            
            Restart-Service -Name SysMain -Force -ErrorAction Stop
            
            Write-Host "  [SUCCESS] Registry updated! SysMain is now locked to Mode $suggestedMode.`n" -ForegroundColor Green
        } catch {
            Write-Host "  [ERROR] Failed to apply settings!" -ForegroundColor Red
            Write-Host "  Reason: $($_.Exception.Message)`n" -ForegroundColor Red
        }
    } else {
        Write-Host "  Skipped SysMain optimization.`n" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  SysMain is already optimized.`n" -ForegroundColor Green
}