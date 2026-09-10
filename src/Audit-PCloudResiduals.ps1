<#
.SYNOPSIS
    pCloud Residual Audio Audit & Empty Shell Sweeper

.DESCRIPTION
    Scans G:\My Drive\pcloud for residual uncataloged audiobooks, moves them into
    G:\My Drive\04_Media\Organized Audiobooks\_Uncataloged, and sweeps resulting empty
    directory shells in pCloud into G:\My Drive\pcloud\To Delete Empty Folders.

    Safeguards:
    - Long-path \\?\ handling with .NET System.IO
    - Zero deletions (STRICTLY_DENY(Remove-Item))
    - Zero interaction with P:\ drive (STRICTLY_DENY(Access: "P:\*"))
    - 3-tier exponential retry backoff
    - Non-media folders (Documents, PyCharm, etc.) strictly preserved in pCloud
    - Comprehensive CSV logging to Manual_Review_Log.csv
#>
[CmdletBinding(SupportsShouldProcess)]
Param(
    [Parameter(Mandatory=$false)]
    [string]$PCloudSourcePath = "G:\My Drive\pcloud",

    [Parameter(Mandatory=$false)]
    [string]$TargetUncatalogedPath = "G:\My Drive\04_Media\Organized Audiobooks\_Uncataloged",

    [Parameter(Mandatory=$false)]
    [string]$PCloudHoldingCellPath = "G:\My Drive\pcloud\To Delete Empty Folders",

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "G:\My Drive\04_Media\Manual_Review_Log.csv"
)

$ErrorActionPreference = "Stop"

# Boundary Assertion: P:\ drive access is strictly prohibited
if ($PCloudSourcePath -like "P:\*" -or $TargetUncatalogedPath -like "P:\*" -or $PCloudHoldingCellPath -like "P:\*") {
    throw "Security Boundary Violation: Access to P:\ drive is strictly prohibited."
}

function Move-PayloadWithRetry {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [bool]$IsFile = $false
    )
    $maxRetries = 3
    $retryIntervals = @(2, 4, 8)
    $destParent = [System.IO.Path]::GetDirectoryName($DestinationPath)
    if (-not [System.IO.Directory]::Exists("\\?\$destParent")) {
        [System.IO.Directory]::CreateDirectory("\\?\$destParent") | Out-Null
    }

    $attempt = 0
    while ($attempt -le $maxRetries) {
        try {
            if ($IsFile) {
                [System.IO.File]::Move("\\?\$SourcePath", "\\?\$DestinationPath")
            } else {
                [System.IO.Directory]::Move("\\?\$SourcePath", "\\?\$DestinationPath")
            }
            return $true
        } catch {
            if ($attempt -eq $maxRetries) {
                Write-Warning "Failed to move '$SourcePath' after $($maxRetries) retries: $_"
                return $false
            }
            Start-Sleep -Seconds $retryIntervals[$attempt]
            $attempt++
        }
    }
}

function Log-Action {
    param(
        [string]$Action,
        [string]$Source,
        [string]$Destination,
        [string]$Reason
    )
    $date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "`"$date`",`"$Action`",`"$Source`",`"$Destination`",`"$Reason`""
    if ([System.IO.File]::Exists("\\?\$LogPath")) {
        [System.IO.File]::AppendAllText("\\?\$LogPath", "$logEntry`r`n", [System.Text.Encoding]::UTF8)
    }
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  PCLOUD RESIDUAL AUDIO AUDIT & SWEEPER ENGINE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Ensure Target Directories Exist
if (-not [System.IO.Directory]::Exists("\\?\$TargetUncatalogedPath")) {
    [System.IO.Directory]::CreateDirectory("\\?\$TargetUncatalogedPath") | Out-Null
}
if (-not [System.IO.Directory]::Exists("\\?\$PCloudHoldingCellPath")) {
    [System.IO.Directory]::CreateDirectory("\\?\$PCloudHoldingCellPath") | Out-Null
}

$audioExts = @('.m4b', '.mp3', '.m4a', '.flac', '.aac', '.wav', '.wma')
$ignoredFolderNames = @('$RECYCLE.BIN', '.Trash-1000', 'To Delete', 'To Delete Audio Books', 'To Delete Empty Folders', 'System Volume Information')

# 2. Discover Residual Audio Folders in pCloud
Write-Host "[1/3] Scanning pCloud for residual audiobooks..." -ForegroundColor Yellow
$pcloudDirInfo = [System.IO.DirectoryInfo]::new("\\?\$PCloudSourcePath")
$candidateQueue = [System.Collections.Generic.Queue[System.IO.DirectoryInfo]]::new()
$candidateQueue.Enqueue($pcloudDirInfo)

$residualAudioFolders = [System.Collections.Generic.List[System.IO.DirectoryInfo]]::new()
$residualAudioFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

while ($candidateQueue.Count -gt 0) {
    $current = $candidateQueue.Dequeue()
    if ($ignoredFolderNames -contains $current.Name) { continue }

    $subDirs = @()
    $files = @()
    try {
        $subDirs = @($current.GetDirectories())
        $files = @($current.GetFiles())
    } catch { continue }

    $audioFiles = @($files | Where-Object { $audioExts -contains $_.Extension.ToLower() })
    $discSubdirs = @($subDirs | Where-Object { $_.Name -match '(cd|disc|part)\s*\d+' })

    if ($audioFiles.Count -gt 0 -and $current.Name -eq "Audible") {
        foreach ($af in $audioFiles) { $residualAudioFiles.Add($af) }
    } elseif ($audioFiles.Count -gt 0) {
        $residualAudioFolders.Add($current)
    } elseif ($discSubdirs.Count -gt 0) {
        $hasDiscAudio = $false
        foreach ($dsub in $discSubdirs) {
            try {
                $dAudio = @($dsub.GetFiles() | Where-Object { $audioExts -contains $_.Extension.ToLower() })
                if ($dAudio.Count -gt 0) { $hasDiscAudio = $true; break }
            } catch {}
        }
        if ($hasDiscAudio) {
            $residualAudioFolders.Add($current)
        }
    }

    foreach ($s in $subDirs) {
        if (-not $discSubdirs.Contains($s)) {
            $candidateQueue.Enqueue($s)
        }
    }
}

Write-Host "  Found $($residualAudioFolders.Count) residual audio folders and $($residualAudioFiles.Count) loose audio files." -ForegroundColor White

# 3. Relocate Residual Audio into 04_Media\Organized Audiobooks\_Uncataloged
Write-Host "[2/3] Relocating residual audio into 04_Media\_Uncataloged..." -ForegroundColor Yellow
$relocatedAudioCount = 0

foreach ($folder in $residualAudioFolders) {
    $cleanSrc = $folder.FullName.Replace("\\?\", "")
    $folderName = $folder.Name
    $dest = Join-Path -Path $TargetUncatalogedPath -ChildPath $folderName

    if ([System.IO.Directory]::Exists("\\?\$dest")) {
        $guid = [guid]::NewGuid().ToString().Substring(0, 8)
        $dest = "${dest}_${guid}"
    }

    if ($PSCmdlet.ShouldProcess($cleanSrc, "Relocate residual audio folder to $dest")) {
        $moved = Move-PayloadWithRetry -SourcePath $cleanSrc -DestinationPath $dest -IsFile $false
        if ($moved) {
            $relocatedAudioCount++
            Log-Action -Action "RELOCATE_RESIDUAL_AUDIO" -Source $cleanSrc -Destination $dest -Reason "Uncataloged pCloud audiobook consolidated into 04_Media"
        }
    }
}

foreach ($file in $residualAudioFiles) {
    $cleanSrc = $file.FullName.Replace("\\?\", "")
    $fileName = $file.Name
    $dest = Join-Path -Path $TargetUncatalogedPath -ChildPath $fileName

    if ([System.IO.File]::Exists("\\?\$dest")) {
        $guid = [guid]::NewGuid().ToString().Substring(0, 8)
        $destName = "$([System.IO.Path]::GetFileNameWithoutExtension($fileName))_${guid}$([System.IO.Path]::GetExtension($fileName))"
        $dest = Join-Path -Path $TargetUncatalogedPath -ChildPath $destName
    }

    if ($PSCmdlet.ShouldProcess($cleanSrc, "Relocate residual audio file to $dest")) {
        $moved = Move-PayloadWithRetry -SourcePath $cleanSrc -DestinationPath $dest -IsFile $true
        if ($moved) {
            $relocatedAudioCount++
            Log-Action -Action "RELOCATE_RESIDUAL_AUDIO_FILE" -Source $cleanSrc -Destination $dest -Reason "Uncataloged pCloud audio file consolidated into 04_Media"
        }
    }
}

Write-Host "  Relocated $relocatedAudioCount residual audio items into 04_Media\_Uncataloged." -ForegroundColor Green

# 4. Sweep Empty Directory Shells in pCloud
Write-Host "[3/3] Sweeping empty directory shells in pCloud..." -ForegroundColor Yellow
$sweptEmptyCount = 0

$allPCloudDirs = @()
try {
    $allPCloudDirs = [System.IO.Directory]::GetDirectories("\\?\$PCloudSourcePath", "*", [System.IO.SearchOption]::AllDirectories) |
        Where-Object {
            $_ -notmatch '\\To Delete Empty Folders' -and
            $_ -notmatch '\\\$RECYCLE\.BIN' -and
            $_ -notmatch '\\\.Trash-1000' -and
            $_ -notmatch '\\Drive G\\(Documents|Downloads|Java|PyCharm|Rackspace|AirflowHome|Workout Stuff)'
        } |
        Sort-Object -Property @{Expression={$_.Length}; Descending=$true}
} catch {
    Write-Warning "Error reading pcloud directories: $_"
}

foreach ($dir in $allPCloudDirs) {
    $cleanDir = $dir.Replace("\\?\", "")
    if (-not [System.IO.Directory]::Exists("\\?\$cleanDir")) { continue }

    $dFiles = @()
    $dSubDirs = @()
    try {
        $dFiles = [System.IO.Directory]::GetFiles("\\?\$cleanDir")
        $dSubDirs = [System.IO.Directory]::GetDirectories("\\?\$cleanDir")
    } catch { continue }

    if ($dFiles.Count -eq 0 -and $dSubDirs.Count -eq 0) {
        $dirName = [System.IO.Path]::GetFileName($cleanDir)
        $guid = [guid]::NewGuid().ToString().Substring(0, 8)
        $dest = Join-Path -Path $PCloudHoldingCellPath -ChildPath "${dirName}_${guid}"

        if ($PSCmdlet.ShouldProcess($cleanDir, "Move empty folder to $dest")) {
            $moved = Move-PayloadWithRetry -SourcePath $cleanDir -DestinationPath $dest -IsFile $false
            if ($moved) {
                $sweptEmptyCount++
                Log-Action -Action "MOVE_PCLOUD_EMPTY_SHELL" -Source $cleanDir -Destination $dest -Reason "Emptied pCloud folder shell moved to holding cell"
            }
        }
    }
}

# 5. Holding Cell Audit
$holdingFiles = @([System.IO.Directory]::GetFiles("\\?\$PCloudHoldingCellPath", "*", [System.IO.SearchOption]::AllDirectories))
$holdingDirs = @([System.IO.Directory]::GetDirectories("\\?\$PCloudHoldingCellPath", "*", [System.IO.SearchOption]::AllDirectories))

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  PCLOUD RESIDUAL AUDIT SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Residual Audio Relocated : $relocatedAudioCount" -ForegroundColor Green
Write-Host "  Empty Shells Swept       : $sweptEmptyCount" -ForegroundColor Green
Write-Host "  Holding Cell Shells      : $($holdingDirs.Count)" -ForegroundColor White
Write-Host "  Holding Cell Files       : $($holdingFiles.Count) (0 expected)" -ForegroundColor $(if ($holdingFiles.Count -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================" -ForegroundColor Cyan

return @{
    RelocatedAudio = $relocatedAudioCount
    SweptEmpty = $sweptEmptyCount
    HoldingFiles = $holdingFiles.Count
    HoldingDirs = $holdingDirs.Count
}
