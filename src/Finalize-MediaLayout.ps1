<#
.SYNOPSIS
    Final 04_Media Residual Reconciliation, Layout Finalization & Atomic Rename Engine

.DESCRIPTION
    1. Rescues stranded audio payloads from Drive E and Drive I into Organized Audiobooks\_Uncataloged.
    2. Discards thumbnail/search caches into To Delete Empty Folders.
    3. Sweeps defunct legacy directories (Drive E, Drive I, Drive G, old Audiobooks shell) into To Delete Empty Folders.
    4. Atomically renames Organized Audiobooks -> Audiobooks.
    5. Appends all actions to Manual_Review_Log.csv.

    Safeguards:
    - Zero permanent deletions (STRICTLY_DENY(Remove-Item))
    - Zero P:\ interactions (STRICTLY_DENY(Access: "P:\*"))
    - Long path prefix handling (\\?\)
    - Retry logic with backoff
#>
[CmdletBinding(SupportsShouldProcess)]
Param(
    [Parameter(Mandatory=$false)]
    [string]$MediaRoot = "G:\My Drive\04_Media",

    [Parameter(Mandatory=$false)]
    [string]$OrganizedPath = "G:\My Drive\04_Media\Organized Audiobooks",

    [Parameter(Mandatory=$false)]
    [string]$TargetAudiobooksPath = "G:\My Drive\04_Media\Audiobooks",

    [Parameter(Mandatory=$false)]
    [string]$EmptyFoldersHoldingCell = "G:\My Drive\04_Media\To Delete Empty Folders",

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "G:\My Drive\04_Media\Manual_Review_Log.csv"
)

$ErrorActionPreference = "Stop"

if ($MediaRoot -like "P:\*" -or $OrganizedPath -like "P:\*" -or $TargetAudiobooksPath -like "P:\*") {
    throw "Security Boundary Violation: Access to P:\ drive is strictly prohibited."
}

function Write-AuditEntry {
    param(
        [string]$Action,
        [string]$Source,
        [string]$Destination,
        [string]$Notes
    )
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $cleanAction = $Action -replace '"', '""'
    $cleanSrc = $Source -replace '"', '""'
    $cleanDst = $Destination -replace '"', '""'
    $cleanNotes = $Notes -replace '"', '""'
    $line = "`"$ts`",`"$cleanAction`",`"$cleanSrc`",`"$cleanDst`",`"$cleanNotes`""

    $maxRetries = 3
    for ($i = 0; $i -lt $maxRetries; $i++) {
        try {
            [System.IO.File]::AppendAllLines("\\?\$LogPath", @($line), [System.Text.Encoding]::UTF8)
            break
        } catch {
            Start-Sleep -Seconds 1
        }
    }
}

function Move-SafeItem {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [bool]$IsFile = $false
    )
    $destParent = [System.IO.Path]::GetDirectoryName($DestinationPath)
    if (-not [System.IO.Directory]::Exists("\\?\$destParent")) {
        [System.IO.Directory]::CreateDirectory("\\?\$destParent") | Out-Null
    }

    $retries = 3
    for ($attempt = 1; $attempt -le $retries; $attempt++) {
        try {
            if ($IsFile) {
                if ([System.IO.File]::Exists("\\?\$SourcePath")) {
                    [System.IO.File]::Move("\\?\$SourcePath", "\\?\$DestinationPath")
                    return $true
                }
            } else {
                if ([System.IO.Directory]::Exists("\\?\$SourcePath")) {
                    [System.IO.Directory]::Move("\\?\$SourcePath", "\\?\$DestinationPath")
                    return $true
                }
            }
        } catch {
            if ($attempt -eq $retries) {
                Write-Warning "Failed to move $SourcePath to $DestinationPath : $_"
                return $false
            }
            Start-Sleep -Seconds ($attempt * 2)
        }
    }
    return $false
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  TASK-016: 04_MEDIA FINAL RECONCILIATION & LAYOUT ENGINE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# STEP 1: RESCUE AUDIOBOOKS
Write-Host "`n[1/4] Rescuing lingering audiobooks into _Uncataloged..." -ForegroundColor Yellow
$rescueItems = @(
    @{
        Name = "Royal Assassin [B003NTPCVM]"
        Source = Join-Path $MediaRoot "Drive E\To Delete Audio Books\Royal Assassin [B003NTPCVM]"
        Target = Join-Path $OrganizedPath "_Uncataloged\Royal Assassin [B003NTPCVM]"
    },
    @{
        Name = "Heretical Fishing 3 [B0D7XD7PTN]"
        Source = Join-Path $MediaRoot "Drive E\To Delete Empty Folders\Heretical Fishing 3 [B0D7XD7PTN]"
        Target = Join-Path $OrganizedPath "_Uncataloged\Heretical Fishing 3 [B0D7XD7PTN]"
    },
    @{
        Name = "Stephen King - Cell"
        Source = Join-Path $MediaRoot "Drive I\To Delete Empty Folders\stephen king - Cell - audio book + Ebook"
        Target = Join-Path $OrganizedPath "_Uncataloged\stephen king - Cell - audio book + Ebook"
    },
    @{
        Name = "Torchwood (Loose Tracks)"
        Source = Join-Path $MediaRoot "Drive I\To Delete Empty Folders\Torchwood\Torchwood Everyone Says Hello Audiobook\Torchwood - Everyone Says Hello Disc 1"
        Target = Join-Path $OrganizedPath "_Uncataloged\Torchwood - Everyone Says Hello (Loose Tracks)"
    }
)

foreach ($item in $rescueItems) {
    if ([System.IO.Directory]::Exists("\\?\$($item.Source)")) {
        if ($PSCmdlet.ShouldProcess($item.Source, "Rescue audiobook to $($item.Target)")) {
            $ok = Move-SafeItem -SourcePath $item.Source -DestinationPath $item.Target -IsFile $false
            if ($ok) {
                Write-Host "  [RESCUED] $($item.Name)" -ForegroundColor Green
                Write-AuditEntry -Action "RESCUE_AUDIOBOOK" -Source $item.Source -Destination $item.Target -Notes "TASK-016 Rescued stranded audiobook to _Uncataloged"
            }
        }
    } else {
        Write-Host "  [NOT FOUND] $($item.Name) already moved or absent" -ForegroundColor Gray
    }
}

# STEP 2: DISCARD CACHES & SYSTEM REMNANTS
Write-Host "`n[2/4] Discarding thumbnail caches and search indexes..." -ForegroundColor Yellow
$discardItems = @(
    @{
        Name = "Cover Thumbnails (Images)"
        Source = Join-Path $MediaRoot "Drive E\To Delete Empty Folders\Images"
        Target = Join-Path $EmptyFoldersHoldingCell "Drive E_Images_Cache"
        IsFile = $false
    },
    @{
        Name = "SearchEngine Cache"
        Source = Join-Path $MediaRoot "Drive E\To Delete Empty Folders\SearchEngine"
        Target = Join-Path $EmptyFoldersHoldingCell "Drive E_SearchEngine_Cache"
        IsFile = $false
    },
    @{
        Name = "bootTel.dat"
        Source = Join-Path $MediaRoot "Drive G\bootTel.dat"
        Target = Join-Path $EmptyFoldersHoldingCell "bootTel.dat"
        IsFile = $true
    }
)

foreach ($item in $discardItems) {
    $exists = if ($item.IsFile) { [System.IO.File]::Exists("\\?\$($item.Source)") } else { [System.IO.Directory]::Exists("\\?\$($item.Source)") }
    if ($exists) {
        if ($PSCmdlet.ShouldProcess($item.Source, "Discard to holding cell $($item.Target)")) {
            $ok = Move-SafeItem -SourcePath $item.Source -DestinationPath $item.Target -IsFile $item.IsFile
            if ($ok) {
                Write-Host "  [DISCARDED] $($item.Name)" -ForegroundColor Green
                Write-AuditEntry -Action "DISCARD_CACHE" -Source $item.Source -Destination $item.Target -Notes "TASK-016 Discarded cache to To Delete Empty Folders"
            }
        }
    }
}

# STEP 3: SWEEP DEFUNCT DIRECTORY SHELLS
Write-Host "`n[3/4] Sweeping defunct legacy directory shells..." -ForegroundColor Yellow
$defunctShells = @(
    @{
        Name = "Legacy Audiobooks Shell"
        Source = Join-Path $MediaRoot "Audiobooks"
        Target = Join-Path $EmptyFoldersHoldingCell "Audiobooks_Legacy_Shell"
    },
    @{
        Name = "Drive E Shell"
        Source = Join-Path $MediaRoot "Drive E"
        Target = Join-Path $EmptyFoldersHoldingCell "Drive E_Defunct_Shell"
    },
    @{
        Name = "Drive I Shell"
        Source = Join-Path $MediaRoot "Drive I"
        Target = Join-Path $EmptyFoldersHoldingCell "Drive I_Defunct_Shell"
    },
    @{
        Name = "Drive G Shell"
        Source = Join-Path $MediaRoot "Drive G"
        Target = Join-Path $EmptyFoldersHoldingCell "Drive G_Defunct_Shell"
    }
)

foreach ($shell in $defunctShells) {
    if ([System.IO.Directory]::Exists("\\?\$($shell.Source)")) {
        if ($PSCmdlet.ShouldProcess($shell.Source, "Sweep defunct shell to $($shell.Target)")) {
            $ok = Move-SafeItem -SourcePath $shell.Source -DestinationPath $shell.Target -IsFile $false
            if ($ok) {
                Write-Host "  [SWEPT] $($shell.Name)" -ForegroundColor Green
                Write-AuditEntry -Action "SWEEP_DEFUNCT_SHELL" -Source $shell.Source -Destination $shell.Target -Notes "TASK-016 Swept defunct shell to holding cell"
            }
        }
    }
}

# STEP 4: ATOMIC RENAME TO AUDIOBOOKS
Write-Host "`n[4/4] Renaming master library: Organized Audiobooks -> Audiobooks..." -ForegroundColor Yellow
if ([System.IO.Directory]::Exists("\\?\$OrganizedPath")) {
    if (-not $WhatIfPreference -and [System.IO.Directory]::Exists("\\?\$TargetAudiobooksPath")) {
        throw "Collision Error: Target directory '$TargetAudiobooksPath' already exists! Sweeper may not have completed."
    }

    if ($PSCmdlet.ShouldProcess($OrganizedPath, "Atomic Rename to $TargetAudiobooksPath")) {
        $renamed = Move-SafeItem -SourcePath $OrganizedPath -DestinationPath $TargetAudiobooksPath -IsFile $false
        if ($renamed) {
            Write-Host "  [RENAMED] Organized Audiobooks -> Audiobooks SUCCESSFUL!" -ForegroundColor Green
            Write-AuditEntry -Action "RENAME_COLLECTION" -Source $OrganizedPath -Destination $TargetAudiobooksPath -Notes "TASK-016 Renamed master collection to Audiobooks"
        } else {
            throw "Failed to rename $OrganizedPath to $TargetAudiobooksPath."
        }
    }
} else {
    if ([System.IO.Directory]::Exists("\\?\$TargetAudiobooksPath")) {
        Write-Host "  [ALREADY RENAMED] $TargetAudiobooksPath already exists." -ForegroundColor Cyan
    } else {
        throw "Source directory $OrganizedPath not found."
    }
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  TASK-016 PHYSICAL REORGANIZATION COMPLETE!" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
