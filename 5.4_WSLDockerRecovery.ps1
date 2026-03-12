<#
.SYNOPSIS
    Recovers broken WSL distributions and Docker Desktop after a storage controller change.
.DESCRIPTION
    After switching from RAID to AHCI mode (or any storage stack change), Windows
    reassigns volume identifiers. WSL distribution registry entries that pointed to
    the old volume paths break silently — the ext4.vhdx files still exist on disk,
    but Windows can no longer find them.

    This script performs a two-phase search for orphaned ext4.vhdx files and offers
    to remap the registry BasePath keys to their correct new locations.

    Phase 1 — Breadcrumb Search: Checks common WSL and Docker Desktop installation
                                  paths first. Fast; covers 90% of cases.
    Phase 2 — Deep Search:       Recursive drive scan using 'dir /s /b /a' to catch
                                  hidden system files. Slower but exhaustive.

    REQUIRES ADMINISTRATOR — modifies HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss

    ALWAYS EXPORT A REGISTRY BACKUP BEFORE RUNNING:
        reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Lxss" wsl-backup.reg
#>

Write-Host "=== MULTI-PHASE WSL & DOCKER RECOVERY ===" -ForegroundColor Cyan
Write-Host "Checking WSL and Docker Registry Configurations..." -ForegroundColor Cyan

# 1. Identify Broken Distributions
$lxssPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"
$distros = Get-ChildItem -Path $lxssPath | ForEach-Object {
    $props = Get-ItemProperty -Path $_.PSPath
    if ($props.DistributionName) {
        [PSCustomObject]@{ RegistryKey = $_.PSPath; Name = $props.DistributionName; BasePath = $props.BasePath }
    }
}

$brokenDistros = @()
foreach ($distro in $distros) {
    if (-not (Test-Path (Join-Path $distro.BasePath "ext4.vhdx"))) {
        Write-Host "[MISSING] $($distro.Name)" -ForegroundColor Red
        $brokenDistros += $distro
    }
}

if ($brokenDistros.Count -eq 0) {
    Write-Host "All WSL distributions are healthy." -ForegroundColor Green
    exit
}

# 2. Define Search Scope
$allFixedDrives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter
$foundMappings = @{}

Write-Host "`nHunting for missing virtual disks..." -ForegroundColor Yellow

# --- PHASE 1: BREADCRUMB SEARCH (Fast) ---
foreach ($letter in $allFixedDrives) {
    foreach ($distro in $brokenDistros) {
        if ($foundMappings.ContainsKey($distro.Name)) { continue }

        $pathsToCheck = @(
            "${letter}:\DockerData\DockerDesktopWSL\$($distro.Name)\main",
            "${letter}:\WSL\$($distro.Name)",
            "${letter}:\$($distro.Name)"
        )

        foreach ($p in $pathsToCheck) {
            if (Test-Path (Join-Path $p "ext4.vhdx")) {
                $foundMappings[$distro.Name] = $p
                Write-Host "  [FOUND] Quick match for '$($distro.Name)' on ${letter}:\" -ForegroundColor Green
                break
            }
        }
    }
}

# --- PHASE 2: DEEP SEARCH (Exhaustive) ---
$remaining = $brokenDistros | Where-Object { -not $foundMappings.ContainsKey($_.Name) }

if ($remaining) {
    Write-Host "Phase 2: Deep Searching drives..." -ForegroundColor Gray

    foreach ($letter in $allFixedDrives) {
        # Use cmd.exe dir with /s /b /a to catch hidden Docker system files
        $results = cmd.exe /c "dir ${letter}:\ext4.vhdx /s /b /a 2>nul"

        if ($results) {
            foreach ($file in @($results)) {
                $dir = Split-Path $file -Parent

                foreach ($distro in $remaining) {
                    if ($dir -match [regex]::Escape($distro.Name) -and -not $foundMappings.ContainsKey($distro.Name)) {
                        $foundMappings[$distro.Name] = $dir
                        Write-Host "  [FOUND] Deep match for '$($distro.Name)' at $dir" -ForegroundColor Green
                    }
                }
            }
        }
    }
}

# --- RECOVERY ---
$fixesApplied = $false

foreach ($distro in $brokenDistros) {
    if ($foundMappings.ContainsKey($distro.Name)) {
        $newPath = $foundMappings[$distro.Name]
        Write-Host "`nDistribution: $($distro.Name)" -ForegroundColor White
        Write-Host "Located At: $newPath" -ForegroundColor Green

        if ((Read-Host "Apply this fix? (y/n)") -eq 'y') {
            Set-ItemProperty -Path $distro.RegistryKey -Name "BasePath" -Value $newPath
            Write-Host "Registry updated." -ForegroundColor Green
            $fixesApplied = $true
        }
    } else {
        Write-Host "`n[NOT FOUND] $($distro.Name) - Manual intervention required" -ForegroundColor Red
    }
}

if ($fixesApplied) {
    wsl --shutdown
    Write-Host "`nWSL shut down. Changes active on next launch." -ForegroundColor Green
}

Write-Host "`nPress Enter to exit..."
Read-Host

