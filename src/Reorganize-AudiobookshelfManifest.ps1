<#
.SYNOPSIS
    Audiobookshelf Manifest Deduplication & Layout Restructuring Engine

.DESCRIPTION
    Restructures the audiobook library based on docs/audiobookshelf_library.json using a 3-tier match.
    Safeguards: Long-path \\?\, Retry-with-backoff, Atomic payload transfer, Zero deletions.
#>
[CmdletBinding(SupportsShouldProcess)]
Param(
    [Parameter(Mandatory=$true)]
    [string]$LibraryJsonPath,

    [Parameter(Mandatory=$true)]
    [string]$TargetDirectory,

    [Parameter(Mandatory=$true)]
    [string]$HoldingCellDirectory
)

$ErrorActionPreference = "Stop"

function Move-ItemWithRetry {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath
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
            if ($PSCmdlet.ShouldProcess($SourcePath, "Move to $DestinationPath")) {
                [System.IO.Directory]::Move("\\?\$SourcePath", "\\?\$DestinationPath")
            }
            return $true
        }
        catch {
            if ($attempt -eq $maxRetries) {
                Write-Error "Failed to move '$SourcePath' after $($maxRetries) retries. $_"
                throw
            }
            Write-Warning "Lock encountered on '$SourcePath'. Retrying in $($retryIntervals[$attempt]) seconds..."
            Start-Sleep -Seconds $retryIntervals[$attempt]
            $attempt++
        }
    }
}

if (-not (Test-Path -LiteralPath "\\?\$LibraryJsonPath")) {
    throw "Library JSON not found at: $LibraryJsonPath"
}
$libraryData = Get-Content -LiteralPath "\\?\$LibraryJsonPath" -Raw | ConvertFrom-Json

$asinLookup = @{}
$titleAuthorLookup = @{}

foreach ($item in $libraryData.results) {
    if ($item.mediaType -ne "book") { continue }
    
    $metadata = $item.media.metadata
    $asin = $metadata.asin
    $title = $metadata.title
    $author = $metadata.authorName
    $series = $metadata.seriesName
    $subtitle = $metadata.subtitle

    if ([string]::IsNullOrWhiteSpace($asin)) {
        if ($item.path -match '\[([B0-9A-Z]{10})\]') {
            $asin = $matches[1]
        }
    }
    
    $record = @{
        Title = $title
        Author = $author
        Series = $series
        Subtitle = $subtitle
        ASIN = $asin
        Id = $item.id
        Tracks = $item.media.numTracks
        Size = $item.media.size
    }

    if (-not [string]::IsNullOrWhiteSpace($asin)) {
        $asinLookup[$asin] = $record
    }
    
    if (-not [string]::IsNullOrWhiteSpace($title) -and -not [string]::IsNullOrWhiteSpace($author)) {
        $normalizedTitle = ($title -replace '[^\w]', '').ToLower()
        $key = $normalizedTitle
        $titleAuthorLookup[$key] = $record
    }
}

$LogPath = Join-Path -Path (Split-Path -Path $TargetDirectory -Parent) -ChildPath "Manual_Review_Log.csv"
if (-not (Test-Path -LiteralPath "\\?\$LogPath")) {
    "Timestamp,Action,Source,Destination,Reason" | Out-File -LiteralPath "\\?\$LogPath" -Encoding UTF8
}
function Log-Action {
    param($Action, $Source, $Destination, $Reason)
    $date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $csvLine = "`"$date`",`"$Action`",`"$Source`",`"$Destination`",`"$Reason`""
    if ($PSCmdlet.ShouldProcess("Manual_Review_Log.csv", "Append log: $Action - $Reason")) {
        $csvLine | Out-File -LiteralPath "\\?\$LogPath" -Encoding UTF8 -Append
    }
}

$targetDirInfo = [System.IO.DirectoryInfo]::new("\\?\$TargetDirectory")
if (-not $targetDirInfo.Exists) {
    throw "Target directory not found: $TargetDirectory"
}

$allFolders = [System.IO.Directory]::GetDirectories("\\?\$TargetDirectory", "*", [System.IO.SearchOption]::AllDirectories) | Where-Object {
    $_ -notmatch '\\_Uncataloged' -and $_ -notmatch '\\To Delete'
}

$candidateGroups = @{}
$uncatalogedPaths = @()

foreach ($folderPath in $allFolders) {
    if (([System.IO.Directory]::GetFiles($folderPath)).Count -eq 0) { continue }
    if (([System.IO.Directory]::GetDirectories($folderPath)).Count -gt 0) { continue }
    
    $folderName = [System.IO.Path]::GetFileName($folderPath)
    $cleanFolderPath = $folderPath.Replace("\\?\", "")

    $matchedRecord = $null
    $matchTier = 0

    if ($folderName -match '\[([B0-9A-Z]{10})\]') {
        $extractedAsin = $matches[1]
        if ($asinLookup.ContainsKey($extractedAsin)) {
            $matchedRecord = $asinLookup[$extractedAsin]
            $matchTier = 1
        }
    }

    if ($null -eq $matchedRecord) {
        $normalizedName = ($folderName -replace '[^\w]', '').ToLower()
        foreach ($key in $titleAuthorLookup.Keys) {
            if ($normalizedName -match $key) {
                $matchedRecord = $titleAuthorLookup[$key]
                $matchTier = 2
                break
            }
        }
    }

    if ($matchedRecord) {
        $groupId = $matchedRecord.Id
        if (-not $candidateGroups.ContainsKey($groupId)) {
            $candidateGroups[$groupId] = @()
        }
        $folderSize = (Get-ChildItem -LiteralPath "\\?\$cleanFolderPath" -Recurse | Measure-Object -Property Length -Sum).Sum
        $candidateGroups[$groupId] += @{
            Path = $cleanFolderPath
            Tier = $matchTier
            Size = $folderSize
            Record = $matchedRecord
        }
    } else {
        $uncatalogedPaths += $cleanFolderPath
    }
}

foreach ($groupId in $candidateGroups.Keys) {
    $candidates = $candidateGroups[$groupId]
    $record = $candidates[0].Record

    $sortedCandidates = @($candidates | Sort-Object @{Expression={$_.Tier}; Descending=$false}, @{Expression={$_.Size}; Descending=$true})
    $primary = $sortedCandidates[0]

    $safeAuthor = $record.Author -replace '[<>:"/\\|?*]', ''
    $safeTitle = $record.Title -replace '[<>:"/\\|?*]', ''
    $safeSeries = $record.Series -replace '[<>:"/\\|?*]', ''
    $safeSubtitle = $record.Subtitle -replace '[<>:"/\\|?*]', ''
    $asinSuffix = if ($record.ASIN) { " [$($record.ASIN)]" } else { "" }

    if ($safeSubtitle) {
        $safeTitle = "$safeTitle - $safeSubtitle"
    }

    $destFolder = ""
    if ($safeSeries) {
        $destFolder = Join-Path $TargetDirectory "$safeAuthor\$safeSeries\$safeTitle$asinSuffix"
    } else {
        $destFolder = Join-Path $TargetDirectory "$safeAuthor\[Standalone Books]\$safeTitle$asinSuffix"
    }

    if ($primary.Path -ne $destFolder) {
        Move-ItemWithRetry -SourcePath $primary.Path -DestinationPath $destFolder
        Log-Action -Action "RESTORE_CANONICAL" -Source $primary.Path -Destination $destFolder -Reason "Matched Tier $($primary.Tier). Primary original selected."
    }

    for ($i = 1; $i -lt $sortedCandidates.Count; $i++) {
        $secondary = $sortedCandidates[$i]
        $delDest = Join-Path $HoldingCellDirectory ([System.IO.Path]::GetFileName($secondary.Path))
        
        $counter = 1
        $baseName = [System.IO.Path]::GetFileName($secondary.Path)
        while ([System.IO.Directory]::Exists("\\?\$delDest")) {
            $delDest = Join-Path $HoldingCellDirectory "${baseName}_duplicate_$counter"
            $counter++
        }

        Move-ItemWithRetry -SourcePath $secondary.Path -DestinationPath $delDest
        Log-Action -Action "QUARANTINE_DUPLICATE" -Source $secondary.Path -Destination $delDest -Reason "Secondary copy. Outranked by $($primary.Path)."
    }
}

$uncatTargetDir = Join-Path $TargetDirectory "_Uncataloged"
foreach ($uPath in $uncatalogedPaths) {
    $folderName = [System.IO.Path]::GetFileName($uPath)
    $dest = Join-Path $uncatTargetDir $folderName
    
    $counter = 1
    while ([System.IO.Directory]::Exists("\\?\$dest")) {
        $dest = Join-Path $uncatTargetDir "${folderName}_$counter"
        $counter++
    }

    Move-ItemWithRetry -SourcePath $uPath -DestinationPath $dest
    Log-Action -Action "QUARANTINE_UNCATALOGED" -Source $uPath -Destination $dest -Reason "Failed to match any library record."
}
