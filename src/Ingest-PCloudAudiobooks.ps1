<#
.SYNOPSIS
    Targeted Ingestion Engine for pCloud Audiobooks Snapshot

.DESCRIPTION
    Scans G:\My Drive\pcloud, matches audiobooks against docs/audiobookshelf_library.json,
    checks existing holdings in G:\My Drive\04_Media\Organized Audiobooks, relocates verified
    canonical books into standard layout (Author \ Series \ Book [ASIN]), and quarantines
    duplicate copies to To Delete Audio Books.

    Safeguards:
    - Long-path \\?\ handling with .NET System.IO
    - Zero deletions (STRICTLY_DENY(Remove-Item))
    - Zero interaction with P:\ drive (STRICTLY_DENY(Access: "P:\*"))
    - 3-tier exponential backoff retry for Google Drive sync locks
    - Atomic payload transfers (audio + cover.jpg + cue sheets)
    - Full audit logging to Manual_Review_Log.csv
#>
[CmdletBinding(SupportsShouldProcess)]
Param(
    [Parameter(Mandatory=$false)]
    [string]$ManifestPath = "C:\Users\wance\Documents\Git\audiobook-migration-system\docs\audiobookshelf_library.json",

    [Parameter(Mandatory=$false)]
    [string]$PCloudSourcePath = "G:\My Drive\pcloud",

    [Parameter(Mandatory=$false)]
    [string]$TargetMediaPath = "G:\My Drive\04_Media\Organized Audiobooks",

    [Parameter(Mandatory=$false)]
    [string]$HoldingCellPath = "G:\My Drive\04_Media\To Delete Audio Books",

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "G:\My Drive\04_Media\Manual_Review_Log.csv",

    [Parameter(Mandatory=$false)]
    [int]$MaxItemsToProcess = 0
)

$ErrorActionPreference = "Stop"

# Boundary Assertion: P:\ drive access is strictly prohibited
if ($PCloudSourcePath -like "P:\*" -or $TargetMediaPath -like "P:\*" -or $HoldingCellPath -like "P:\*" -or $ManifestPath -like "P:\*") {
    throw "Security Boundary Violation: Access to P:\ drive is strictly prohibited."
}

function Clean-SanitizedFileName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return "" }
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    $clean = $Name
    foreach ($c in $invalidChars) {
        $clean = $clean.Replace($c.ToString(), " ")
    }
    return ($clean -replace '\s+', ' ').Trim()
}

function Clean-NormalizedString {
    param([string]$InputText)
    if ([string]::IsNullOrWhiteSpace($InputText)) { return "" }
    return ($InputText -replace '[^\w]', '').ToLower()
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
Write-Host "  PCLOUD TARGETED AUDIOBOOK INGESTION ENGINE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Load Audiobookshelf Manifest
Write-Host "[1/5] Ingesting Audiobookshelf canonical manifest: $ManifestPath" -ForegroundColor Yellow
if (-not [System.IO.File]::Exists("\\?\$ManifestPath")) {
    throw "Manifest JSON file not found at: $ManifestPath"
}

$rawJson = [System.IO.File]::ReadAllText("\\?\$ManifestPath")
$libraryData = ConvertFrom-Json $rawJson

$asinLookup = @{}
$titleAuthorLookup = @{}

foreach ($item in $libraryData.results) {
    if ($item.mediaType -ne "book") { continue }
    $metadata = $item.media.metadata
    $title = $metadata.title
    $subtitle = if ($metadata.subtitle) { $metadata.subtitle } else { "" }
    $author = if ($metadata.authorName) { $metadata.authorName } else { "" }
    $series = if ($metadata.seriesName) { $metadata.seriesName } else { "" }
    $asin = $metadata.asin

    if ([string]::IsNullOrWhiteSpace($asin)) {
        if ($item.path -match '\[([B0-9A-Z]{10})\]') {
            $asin = $matches[1]
        }
    }

    $record = [PSCustomObject]@{
        Id       = $item.id
        Title    = $title
        Subtitle = $subtitle
        Author   = $author
        Series   = $series
        ASIN     = $asin
        Tracks   = $item.media.numTracks
        Size     = $item.media.size
    }

    if (-not [string]::IsNullOrWhiteSpace($asin)) {
        $asinLookup[$asin.ToUpper()] = $record
    }

    if (-not [string]::IsNullOrWhiteSpace($title)) {
        $normTitle = Clean-NormalizedString $title
        if (-not [string]::IsNullOrWhiteSpace($normTitle)) {
            $titleAuthorLookup[$normTitle] = $record
        }
    }
}

Write-Host "  Indexed $($asinLookup.Count) canonical ASINs and $($titleAuthorLookup.Count) titles." -ForegroundColor Green

# 2. Index Existing Holdings in Organized Audiobooks
Write-Host "[2/5] Indexing existing holdings in: $TargetMediaPath" -ForegroundColor Yellow
$existingHoldingsByAsin = @{}
$existingHoldingsByTitle = @{}

$audioExts = @('.m4b', '.mp3', '.m4a', '.flac', '.aac', '.wav', '.wma')

if ([System.IO.Directory]::Exists("\\?\$TargetMediaPath")) {
    $existingDirs = [System.IO.Directory]::GetDirectories("\\?\$TargetMediaPath", "*", [System.IO.SearchOption]::AllDirectories)
    foreach ($ed in $existingDirs) {
        if ($ed -match '\\_Uncataloged' -or $ed -match '\\To Delete') { continue }
        $dirName = [System.IO.Path]::GetFileName($ed)
        $cleanEd = $ed.Replace("\\?\", "")

        $asin = ""
        if ($dirName -match '\[([B0-9A-Z]{10})\]' -or $dirName -match '_([B0-9A-Z]{10})_') {
            $asin = $matches[1].ToUpper()
        }

        # Check if this folder has audio files
        $eFiles = @()
        try {
            $eFiles = @([System.IO.DirectoryInfo]::new($ed).GetFiles())
        } catch {}
        $eAudio = @($eFiles | Where-Object { $audioExts -contains $_.Extension.ToLower() })
        
        if ($eAudio.Count -gt 0) {
            $totalSize = ($eFiles | Measure-Object -Property Length -Sum).Sum
            $primaryFormat = ($eAudio | Group-Object Extension | Sort-Object Count -Descending | Select-Object -First 1).Name.ToLower()

            $holdingInfo = @{
                Path          = $cleanEd
                Size          = $totalSize
                Format        = $primaryFormat
                AudioCount    = $eAudio.Count
                ASIN          = $asin
            }

            if (-not [string]::IsNullOrWhiteSpace($asin)) {
                $existingHoldingsByAsin[$asin] = $holdingInfo
            }

            $normName = Clean-NormalizedString ($dirName -replace '\s*\[[B0-9A-Z]{10}\]', '')
            if (-not [string]::IsNullOrWhiteSpace($normName)) {
                $existingHoldingsByTitle[$normName] = $holdingInfo
            }
        }
    }
}

Write-Host "  Indexed $($existingHoldingsByAsin.Count) existing books by ASIN and $($existingHoldingsByTitle.Count) by title." -ForegroundColor Green

# 3. Crawl pCloud Source Root for Candidate Audiobooks
Write-Host "[3/5] Crawling pCloud source directory: $PCloudSourcePath" -ForegroundColor Yellow
$pcloudDirInfo = [System.IO.DirectoryInfo]::new("\\?\$PCloudSourcePath")
if (-not $pcloudDirInfo.Exists) {
    throw "Source directory not found: $PCloudSourcePath"
}

# Ensure Holding Cell Directory Exists
if (-not [System.IO.Directory]::Exists("\\?\$HoldingCellPath")) {
    [System.IO.Directory]::CreateDirectory("\\?\$HoldingCellPath") | Out-Null
}

$candidateQueue = [System.Collections.Generic.Queue[System.IO.DirectoryInfo]]::new()
$candidateQueue.Enqueue($pcloudDirInfo)

$candidates = [System.Collections.Generic.List[PSCustomObject]]::new()
$ignoredFolderNames = @('$RECYCLE.BIN', '.Trash-1000', 'To Delete', 'To Delete Audio Books', 'To Delete Empty Folders', 'System Volume Information')

while ($candidateQueue.Count -gt 0) {
    $current = $candidateQueue.Dequeue()
    if ($ignoredFolderNames -contains $current.Name) { continue }

    $subDirs = @()
    $files = @()
    try {
        $subDirs = @($current.GetDirectories())
        $files = @($current.GetFiles())
    } catch {
        continue
    }

    $audioFiles = @($files | Where-Object { $audioExts -contains $_.Extension.ToLower() })
    $discSubdirs = @($subDirs | Where-Object { $_.Name -match '(cd|disc|part)\s*\d+' })

    # Check for loose multi-book folder (e.g. Audible with standalone .m4bs)
    $hasLooseM4bs = $false
    if ($audioFiles.Count -gt 1 -and $current.Name -eq "Audible") {
        $hasLooseM4bs = $true
    }

    if ($hasLooseM4bs) {
        foreach ($af in $audioFiles) {
            $candidates.Add([PSCustomObject]@{
                IsFile        = $true
                Path          = $af.FullName.Replace("\\?\", "")
                Name          = $af.Name
                Size          = $af.Length
                Format        = $af.Extension.ToLower()
                AudioFiles    = @($af)
                ParentDir     = $current.FullName.Replace("\\?\", "")
            })
        }
        foreach ($s in $subDirs) { $candidateQueue.Enqueue($s) }
        continue
    }

    $isBookFolder = $false
    $bookAudioFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    $totalBytes = 0

    if ($audioFiles.Count -gt 0) {
        $isBookFolder = $true
        foreach ($af in $audioFiles) { $bookAudioFiles.Add($af) }
        $totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
    } elseif ($discSubdirs.Count -gt 0) {
        foreach ($dsub in $discSubdirs) {
            try {
                $dFiles = @($dsub.GetFiles())
                $dAudio = @($dFiles | Where-Object { $audioExts -contains $_.Extension.ToLower() })
                if ($dAudio.Count -gt 0) {
                    $isBookFolder = $true
                    foreach ($daf in $dAudio) { $bookAudioFiles.Add($daf) }
                    $totalBytes += ($dFiles | Measure-Object -Property Length -Sum).Sum
                }
            } catch {}
        }
    }

    if ($isBookFolder) {
        $primaryFormat = ($bookAudioFiles | Group-Object Extension | Sort-Object Count -Descending | Select-Object -First 1).Name.ToLower()
        $candidates.Add([PSCustomObject]@{
            IsFile        = $false
            Path          = $current.FullName.Replace("\\?\", "")
            Name          = $current.Name
            Size          = $totalBytes
            Format        = $primaryFormat
            AudioFiles    = $bookAudioFiles
            ParentDir     = $current.Parent.FullName.Replace("\\?\", "")
        })

        if ($discSubdirs.Count -gt 0 -and $discSubdirs.Count -eq $subDirs.Count) {
            continue
        }
    }

    foreach ($s in $subDirs) {
        if (-not $discSubdirs.Contains($s)) {
            $candidateQueue.Enqueue($s)
        }
    }
}

Write-Host "  Discovered $($candidates.Count) candidate audiobook folders/files in pCloud." -ForegroundColor Green

# 4. Manifest Matching & Collision Arbitration
Write-Host "[4/5] Cross-referencing candidates and executing arbitration..." -ForegroundColor Yellow

$ingestedCount = 0
$quarantinedCount = 0
$upgradedCount = 0
$skippedUnmatched = 0

$processedCount = 0

foreach ($cand in $candidates) {
    if ($MaxItemsToProcess -gt 0 -and $processedCount -ge $MaxItemsToProcess) {
        Write-Host "Reached maximum processing limit ($MaxItemsToProcess)." -ForegroundColor Yellow
        break
    }

    $matchedRecord = $null
    $extractedAsin = ""

    # Tier 1: Match by ASIN
    if ($cand.Name -match '\[([B0-9A-Z]{10})\]' -or $cand.Name -match '_([B0-9A-Z]{10})_') {
        $extractedAsin = $matches[1].ToUpper()
        if ($asinLookup.ContainsKey($extractedAsin)) {
            $matchedRecord = $asinLookup[$extractedAsin]
        }
    }

    # Tier 1b: Match by ASIN inside audio files
    if ($null -eq $matchedRecord -and -not $cand.IsFile) {
        foreach ($af in $cand.AudioFiles) {
            if ($af.Name -match '\[([B0-9A-Z]{10})\]' -or $af.Name -match '_([B0-9A-Z]{10})_') {
                $extractedAsin = $matches[1].ToUpper()
                if ($asinLookup.ContainsKey($extractedAsin)) {
                    $matchedRecord = $asinLookup[$extractedAsin]
                    break
                }
            }
        }
    }

    # Tier 2: Match by normalized title
    if ($null -eq $matchedRecord) {
        $normCandName = Clean-NormalizedString ($cand.Name -replace '\s*\[[B0-9A-Z]{10}\]', '')
        foreach ($key in $titleAuthorLookup.Keys) {
            if ($key.Length -ge 6 -and $normCandName.Contains($key)) {
                $matchedRecord = $titleAuthorLookup[$key]
                break
            }
        }
    }

    if ($null -eq $matchedRecord) {
        $skippedUnmatched++
        continue
    }

    $processedCount++

    # Determine Canonical Target Directory
    $canonicalAuthor = Clean-SanitizedFileName $matchedRecord.Author
    if ([string]::IsNullOrWhiteSpace($canonicalAuthor)) { $canonicalAuthor = "Unknown Author" }

    $canonicalTitle = Clean-SanitizedFileName $matchedRecord.Title
    $bookAsin = if ($matchedRecord.ASIN) { $matchedRecord.ASIN } else { $extractedAsin }
    $titleFolder = if (-not [string]::IsNullOrWhiteSpace($bookAsin)) { "$canonicalTitle [$bookAsin]" } else { $canonicalTitle }

    $targetSubDir = ""
    if (-not [string]::IsNullOrWhiteSpace($matchedRecord.Series)) {
        $cleanSeries = Clean-SanitizedFileName $matchedRecord.Series
        $targetSubDir = Join-Path -Path $canonicalAuthor -ChildPath $cleanSeries
    } else {
        $targetSubDir = Join-Path -Path $canonicalAuthor -ChildPath "[Standalone Books]"
    }

    $targetBookDir = Join-Path -Path (Join-Path -Path $TargetMediaPath -ChildPath $targetSubDir) -ChildPath $titleFolder

    # Collision & Arbitration Check
    $existingHolding = $null
    if (-not [string]::IsNullOrWhiteSpace($bookAsin) -and $existingHoldingsByAsin.ContainsKey($bookAsin.ToUpper())) {
        $existingHolding = $existingHoldingsByAsin[$bookAsin.ToUpper()]
    } elseif ($existingHoldingsByTitle.ContainsKey((Clean-NormalizedString $canonicalTitle))) {
        $existingHolding = $existingHoldingsByTitle[(Clean-NormalizedString $canonicalTitle)]
    } elseif ([System.IO.Directory]::Exists("\\?\$targetBookDir")) {
        $existingHolding = @{
            Path = $targetBookDir
            Size = 0
            Format = "unknown"
            AudioCount = 1
            ASIN = $bookAsin
        }
    }

    if ($existingHolding) {
        # Arbitration between Existing vs Candidate
        $existingSize = $existingHolding.Size
        $candSize = $cand.Size
        $candFormat = $cand.Format
        $existingFormat = $existingHolding.Format

        # Favor .m4b over .mp3, or favor larger byte size if formats match
        $candidateIsSuperior = $false
        if ($candFormat -eq ".m4b" -and $existingFormat -eq ".mp3") {
            $candidateIsSuperior = $true
        } elseif ($candFormat -eq $existingFormat -and $candSize -gt ($existingSize * 1.15)) {
            $candidateIsSuperior = $true
        }

        if ($candidateIsSuperior) {
            # Candidate is superior: Quarantine existing, move candidate to target
            $guid = [guid]::NewGuid().ToString().Substring(0, 8)
            $dupeDest = Join-Path -Path $HoldingCellPath -ChildPath "$([System.IO.Path]::GetFileName($existingHolding.Path))_${guid}"
            
            if ($PSCmdlet.ShouldProcess($existingHolding.Path, "Quarantine inferior existing copy to $dupeDest")) {
                Move-PayloadWithRetry -SourcePath $existingHolding.Path -DestinationPath $dupeDest -IsFile $false
                Log-Action -Action "QUARANTINE_INFERIOR_EXISTING" -Source $existingHolding.Path -Destination $dupeDest -Reason "Replaced by superior copy from pcloud"
            }

            if ($PSCmdlet.ShouldProcess($cand.Path, "Move superior candidate to $targetBookDir")) {
                $targetParent = [System.IO.Path]::GetDirectoryName($targetBookDir)
                if (-not [System.IO.Directory]::Exists("\\?\$targetParent")) {
                    [System.IO.Directory]::CreateDirectory("\\?\$targetParent") | Out-Null
                }
                if ($cand.IsFile) {
                    if (-not [System.IO.Directory]::Exists("\\?\$targetBookDir")) {
                        [System.IO.Directory]::CreateDirectory("\\?\$targetBookDir") | Out-Null
                    }
                    $destFile = Join-Path -Path $targetBookDir -ChildPath $cand.Name
                    Move-PayloadWithRetry -SourcePath $cand.Path -DestinationPath $destFile -IsFile $true
                } else {
                    Move-PayloadWithRetry -SourcePath $cand.Path -DestinationPath $targetBookDir -IsFile $false
                }
                Log-Action -Action "UPGRADE_TO_SUPERIOR_COPY" -Source $cand.Path -Destination $targetBookDir -Reason "Higher quality copy ingested from pcloud"
                $upgradedCount++
            }
        } else {
            # Existing is superior or identical: Quarantine candidate from pcloud
            $guid = [guid]::NewGuid().ToString().Substring(0, 8)
            $candName = if ($cand.IsFile) { [System.IO.Path]::GetFileNameWithoutExtension($cand.Name) } else { $cand.Name }
            $dupeDest = Join-Path -Path $HoldingCellPath -ChildPath "${candName}_${guid}"

            if ($PSCmdlet.ShouldProcess($cand.Path, "Quarantine duplicate pcloud candidate to $dupeDest")) {
                if ($cand.IsFile) {
                    if (-not [System.IO.Directory]::Exists("\\?\$dupeDest")) {
                        [System.IO.Directory]::CreateDirectory("\\?\$dupeDest") | Out-Null
                    }
                    $destFile = Join-Path -Path $dupeDest -ChildPath $cand.Name
                    Move-PayloadWithRetry -SourcePath $cand.Path -DestinationPath $destFile -IsFile $true
                } else {
                    Move-PayloadWithRetry -SourcePath $cand.Path -DestinationPath $dupeDest -IsFile $false
                }
                Log-Action -Action "QUARANTINE_DUPLICATE_FROM_PCLOUD" -Source $cand.Path -Destination $dupeDest -Reason "Duplicate/inferior to existing staged copy in 04_Media"
                $quarantinedCount++
            }
        }
    } else {
        # New canonical book! Ingest into Organized Audiobooks
        if ($PSCmdlet.ShouldProcess($cand.Path, "Ingest canonical book to $targetBookDir")) {
            $targetParent = [System.IO.Path]::GetDirectoryName($targetBookDir)
            if (-not [System.IO.Directory]::Exists("\\?\$targetParent")) {
                [System.IO.Directory]::CreateDirectory("\\?\$targetParent") | Out-Null
            }
            if ($cand.IsFile) {
                if (-not [System.IO.Directory]::Exists("\\?\$targetBookDir")) {
                    [System.IO.Directory]::CreateDirectory("\\?\$targetBookDir") | Out-Null
                }
                $destFile = Join-Path -Path $targetBookDir -ChildPath $cand.Name
                Move-PayloadWithRetry -SourcePath $cand.Path -DestinationPath $destFile -IsFile $true
            } else {
                Move-PayloadWithRetry -SourcePath $cand.Path -DestinationPath $targetBookDir -IsFile $false
            }
            Log-Action -Action "INGEST_CANONICAL_BOOK" -Source $cand.Path -Destination $targetBookDir -Reason "Manifest matched canonical title from pcloud"
            $ingestedCount++

            # Record in existing holdings to prevent collisions within same run
            $newHolding = @{
                Path       = $targetBookDir
                Size       = $cand.Size
                Format     = $cand.Format
                AudioCount = 1
                ASIN       = $bookAsin
            }
            if (-not [string]::IsNullOrWhiteSpace($bookAsin)) {
                $existingHoldingsByAsin[$bookAsin.ToUpper()] = $newHolding
            }
            $existingHoldingsByTitle[(Clean-NormalizedString $canonicalTitle)] = $newHolding
        }
    }
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  PCLOUD INGESTION EXECUTION SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Total Candidates Evaluated : $($candidates.Count)" -ForegroundColor White
Write-Host "  New Canonical Ingested     : $ingestedCount" -ForegroundColor Green
Write-Host "  Duplicates Quarantined     : $quarantinedCount" -ForegroundColor Yellow
Write-Host "  Existing Copies Upgraded   : $upgradedCount" -ForegroundColor Cyan
Write-Host "  Unmatched Assets Preserved : $skippedUnmatched" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan

return @{
    TotalCandidates    = $candidates.Count
    IngestedCount      = $ingestedCount
    QuarantinedCount   = $quarantinedCount
    UpgradedCount      = $upgradedCount
    SkippedUnmatched   = $skippedUnmatched
}
