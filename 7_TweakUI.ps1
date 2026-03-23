<#
.SYNOPSIS
    Optimizes Windows Visual Effects for Performance while preserving readability.
.DESCRIPTION
    1. Sets Visual Effects to "Custom" mode (bypasses "Best Performance" limitations).
    2. Disables window animations and taskbar animations.
    3. Explicitly ENABLES ClearType font smoothing (prevents Windows 95-style text rendering).
    4. Preserves Quality of Life settings: thumbnails, translucent selection, and icon shadows.
    
    This avoids the "Best Performance" preset which disables ClearType alongside animations.
#>

Write-Host "Configuring Visual Effects (Performance + Font Smoothing)..." -ForegroundColor Cyan

# Define the Registry Paths
$visualFxPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
$advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$desktopPath  = "HKCU:\Control Panel\Desktop"
$metricsPath  = "HKCU:\Control Panel\Desktop\WindowMetrics"

try {
    # 1. Force Master Switch to "Custom" (Value: 3)
    Set-ItemProperty -Path $visualFxPath -Name "VisualFXSetting" -Value 3 -Type DWord -Force

    # 2. Kill the big animations (Window Minimize/Maximize and Taskbar shifting)
    Set-ItemProperty -Path $metricsPath -Name "MinAnimate" -Value "0" -Type String -Force
    Set-ItemProperty -Path $advancedPath -Name "TaskbarAnimations" -Value 0 -Type DWord -Force

    # 3. Explicitly ENABLE Font Smoothing (ClearType)
    Set-ItemProperty -Path $desktopPath -Name "FontSmoothing" -Value "2" -Type String -Force
    Set-ItemProperty -Path $desktopPath -Name "FontSmoothingType" -Value 2 -Type DWord -Force

    # 4. Quality of Life Essentials (Keeps the OS from looking completely cursed)
    Set-ItemProperty -Path $advancedPath -Name "IconsOnly" -Value 0 -Type DWord -Force           # 0 = Show Thumbnails
    Set-ItemProperty -Path $advancedPath -Name "ListviewAlphaSelect" -Value 1 -Type DWord -Force # Translucent selection box
    Set-ItemProperty -Path $advancedPath -Name "ListviewShadow" -Value 1 -Type DWord -Force      # Icon text shadows

    Write-Host "  [SUCCESS] Visual effects optimized.`n" -ForegroundColor Green
    
    # 5. Restart Explorer to apply changes immediately
    if ((Read-Host "  Restart Windows Explorer to apply changes now? (y/n)") -eq 'y') {
        Write-Host "  Restarting Explorer..." -ForegroundColor Yellow
        Stop-Process -Name explorer -Force
        # Windows will automatically relaunch explorer.exe natively
    }
} catch {
    Write-Host "  [ERROR] Failed to update Visual Effects." -ForegroundColor Red
    Write-Host "  Reason: $($_.Exception.Message)`n" -ForegroundColor Red
}