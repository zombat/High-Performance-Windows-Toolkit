<#
.SYNOPSIS
    Analyzes the Windows Search Indexer service, database size, and volume indexing scopes.

.DESCRIPTION
    The Windows Search indexer can cause severe disk contention, especially on mechanical 
    HDDs, by constantly cataloging background file changes. This script checks the size of 
    the raw Windows.edb database to detect bloat, and uses CIM to evaluate the IndexingEnabled 
    flag on all fixed volumes. 
    
    If it detects that mechanical drives are included in the indexing scope, it flags them 
    as a performance risk and offers to programmatically disable indexing for those volumes, 
    stopping the background thrashing at the filesystem level.
#>

Write-Host "Analyzing Windows Search Indexer & Disk Contention..." -ForegroundColor Cyan

# STRICT ADMIN CHECK
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  [CRITICAL ERROR] You must run PowerShell as Administrator!" -ForegroundColor Red
    return
}

try {
    # 1. Check Service Status
    $searchSvc = Get-Service -Name WSearch -ErrorAction SilentlyContinue
    if (-not $searchSvc -or $searchSvc.Status -ne 'Running') {
        Write-Host "  [INFO] Windows Search service is currently stopped or disabled." -ForegroundColor DarkGray
    } else {
        Write-Host "  Service:       Running ($($searchSvc.StartType))" -ForegroundColor White
    }

    # 2. Check Database Size (Windows.edb)
    # The file is often locked by the system, so we use Get-Item -Force and catch access errors
    $edbPath = "C:\ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb"
    $edbSizeGB = 0
    
    if (Test-Path $edbPath) {
        $edbFile = Get-Item -Path $edbPath -Force -ErrorAction SilentlyContinue
        if ($edbFile) {
            $edbSizeGB = [math]::Round($edbFile.Length / 1GB, 2)
            $edbColor = if ($edbSizeGB -gt 2) { "Yellow" } else { "White" }
            Write-Host "  Database Size: $edbSizeGB GB" -ForegroundColor $edbColor
            
            if ($edbSizeGB -gt 2) {
                Write-Host "  [WARNING] The index database is quite large. Consider rebuilding it via 'Indexing Options'." -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Database Size: [Locked by System - Cannot Read]" -ForegroundColor DarkGray
        }
    }

    # 3. Map Physical Disks and Check Volume Indexing Flags
    Write-Host "`n  Checking Volume Indexing Scopes..." -ForegroundColor Gray
    
    $volumes = Get-CimInstance Win32_Volume -Filter "DriveType=3 AND DriveLetter IS NOT NULL"
    $hddVols = @()
    $ssdTarget = "C:" # Fallback
    
    $needsFix = $false
    
    foreach ($vol in $volumes) {
        $letter = $vol.DriveLetter
        $isIndexed = $vol.IndexingEnabled
        
        # Determine MediaType via partition mapping
        $mediaType = "Unknown"
        $partition = Get-Partition -DriveLetter $letter.Substring(0,1) -ErrorAction SilentlyContinue
        if ($partition) {
            $disk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $partition.DiskNumber }
            if ($disk) { $mediaType = $disk.MediaType }
        }

        # Display Logic
        if ($mediaType -eq 'SSD') {
            $ssdTarget = $letter
            Write-Host "    $letter ($mediaType)`t Indexed: $isIndexed" -ForegroundColor DarkGray
        } elseif ($mediaType -eq 'HDD') {
            $color = if ($isIndexed) { "Red" } else { "Green" }
            Write-Host "    $letter ($mediaType)`t Indexed: $isIndexed" -ForegroundColor $color
            
            if ($isIndexed) {
                Write-Host "      -> [CRITICAL] Indexing is active on a mechanical drive! This causes heavy I/O thrashing." -ForegroundColor Red
                $hddVols += $vol
                $needsFix = $true
            }
        }
    }

    # 4. Apply Fix
    if ($needsFix) {
        if ((Read-Host "`n  Disable indexing on all mechanical HDDs? (y/n)") -eq 'y') {
            foreach ($badVol in $hddVols) {
                Write-Host "  Disabling indexing on $($badVol.DriveLetter)..." -ForegroundColor Yellow
                $badVol | Set-CimInstance -Property @{IndexingEnabled=$false} -ErrorAction Stop
            }
            
            # Restart the service to drop the file handles on the HDDs
            if ($searchSvc -and $searchSvc.Status -eq 'Running') {
                Write-Host "  Restarting WSearch service to release database handles..." -ForegroundColor Yellow
                Restart-Service -Name WSearch -Force -ErrorAction SilentlyContinue
            }
            
            Write-Host "  [SUCCESS] Mechanical drives removed from indexing scope." -ForegroundColor Green
            Write-Host "  [NOTE] The UI in 'Drive Properties' may take a moment to reflect this change." -ForegroundColor DarkGray
        } else {
            Write-Host "  Skipped Windows Search optimization.`n" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "`n  [OK] No mechanical drives are currently being indexed. Configuration is optimal." -ForegroundColor Green
    }

} catch {
    Write-Host "  [ERROR] Failed to query or modify Windows Search configuration." -ForegroundColor Red
    Write-Host "  Reason: $($_.Exception.Message)`n" -ForegroundColor Red
}