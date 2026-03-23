<#
.SYNOPSIS
    Analyzes system RAM and physical disk types to optimize the Windows Pagefile configuration and remove orphaned pagefiles.

.DESCRIPTION
    This script evaluates total physical memory and maps drive volumes to their physical mediums (HDD vs SSD). It enforces modern best practices for high-RAM systems (32GB+) by replacing space-wasting "System Managed" pagefiles with a strict 2048MB/4096MB lock exclusively on an SSD. 
    
    It bypasses WMI/CIM serialization locks by writing the configuration directly to the PagingFiles registry MultiString. Additionally, it performs a deep scan of all fixed drives for active or dormant 'pagefile.sys' files. Any pagefiles found on non-target drives are flagged as orphans, and a self-destructing SYSTEM-level Scheduled Task is created to silently delete them on the next reboot.

    NOTE: 
    - You must run this script as Administrator.
    - A system reboot is strictly required for the Windows Kernel to release the old pagefile locks and build the new configuration.
    - The automated cleanup task runs as NT AUTHORITY\SYSTEM at startup, forcefully deletes the orphaned files, and then unregisters itself completely leaving no trace.
#>

    Write-Host "  Scanning all fixed drives for orphaned pagefiles..." -ForegroundColor Gray
    $orphans = @()
    
    # Get all drive letters currently attached
    $allFixedDrives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter

    foreach ($letter in $allFixedDrives) {
        $potentialPagefile = "${letter}:\pagefile.sys"
        
        # Use Get-Item with -Force to grab hidden/system files safely in PS 5.1
        $foundFile = Get-Item -Path $potentialPagefile -Force -ErrorAction SilentlyContinue
        
        if ($foundFile) {
            $fileSizeGB = [math]::Round($foundFile.Length / 1GB, 2)
            $isHDD = $hddDrives -contains $letter
            $color = if ($isHDD) { "Red" } else { "Yellow" }
            
            Write-Host "  Found:         $potentialPagefile ($fileSizeGB GB)" -ForegroundColor $color
            if ($isHDD) { Write-Host "  [CRITICAL] Pagefile is on an HDD!" -ForegroundColor Red }

            # If this file is NOT on our new target drive, it's an orphan and must die
            if ($letter -ne $targetDrive) {
                Write-Host "    -> Flagged as Orphan for deletion." -ForegroundColor DarkGray
                $orphans += $potentialPagefile
            } else {
                Write-Host "    -> Target drive. Will be resized/overwritten by Windows." -ForegroundColor DarkGray
            }
        }
    }

    if ($orphans.Count -eq 0) {
        Write-Host "  [OK] No orphans found on secondary drives." -ForegroundColor Green
    }