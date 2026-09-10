<#
.SYNOPSIS
    Master Media Catalog Generation Engine (Spreadsheet Index)

.DESCRIPTION
    Scans G:\My Drive\04_Media\Organized Audiobooks, cross-references each audiobook against
    docs/audiobookshelf_library.json, and exports an interactive, comprehensive spreadsheet
    (G:\My Drive\04_Media\Media_Master_Catalog.csv).

    Safeguards:
    - Long-path \\?\ handling with .NET System.IO
    - Zero deletions (STRICTLY_DENY(Remove-Item))
    - Zero interaction with P:\ drive (STRICTLY_DENY(Access: "P:\*"))
    - Clean UTF-8 CSV formatting importable into Google Sheets / Excel
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [string]$LibraryJsonPath = "C:\Users\wance\Documents\Git\audiobook-migration-system\docs\audiobookshelf_library.json",

    [Parameter(Mandatory=$false)]
    [string]$OrganizedAudiobooksPath = "G:\My Drive\04_Media\Audiobooks",

    [Parameter(Mandatory=$false)]
    [string]$OutputCsvPath = "G:\My Drive\04_Media\Audiobooks\Media_Master_Catalog.csv"
)

$ErrorActionPreference = "Stop"

# Boundary Assertion: P:\ drive access is strictly prohibited
if ($OrganizedAudiobooksPath -like "P:\*" -or $OutputCsvPath -like "P:\*" -or $LibraryJsonPath -like "P:\*") {
    throw "Security Boundary Violation: Access to P:\ drive is strictly prohibited."
}

function Format-DurationSeconds {
    param([double]$Seconds)
    if ($Seconds -le 0) { return "" }
    $ts = [timespan]::FromSeconds($Seconds)
    $hours = [Math]::Floor($ts.TotalHours)
    $mins = $ts.Minutes
    $secs = $ts.Seconds
    return ("{0:D2}:{1:D2}:{2:D2}" -f [int]$hours, [int]$mins, [int]$secs)
}

function Clean-NormalizedString {
    param([string]$InputText)
    if ([string]::IsNullOrWhiteSpace($InputText)) { return "" }
    return ($InputText -replace '[^\w]', '').ToLower()
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  MASTER MEDIA CATALOG GENERATION ENGINE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Load and Parse Audiobookshelf Library JSON
Write-Host "[1/4] Loading canonical metadata from: $LibraryJsonPath" -ForegroundColor Yellow
if (-not [System.IO.File]::Exists("\\?\$LibraryJsonPath")) {
    throw "Library JSON file not found at: $LibraryJsonPath"
}

$rawJson = [System.IO.File]::ReadAllText("\\?\$LibraryJsonPath")
$libraryData = ConvertFrom-Json $rawJson

$asinLookup = @{}
$titleAuthorLookup = @{}
$canonicalCount = 0

foreach ($item in $libraryData.results) {
    if ($item.mediaType -ne "book") { continue }
    $canonicalCount++

    $metadata = $item.media.metadata
    $title = $metadata.title
    $subtitle = if ($metadata.subtitle) { $metadata.subtitle } else { "" }
    $author = if ($metadata.authorName) { $metadata.authorName } else { "" }
    $narrator = if ($metadata.narratorName) { $metadata.narratorName } else { "" }
    $asin = $metadata.asin

    if ([string]::IsNullOrWhiteSpace($asin)) {
        if ($item.path -match '\[([B0-9A-Z]{10})\]') {
            $asin = $matches[1]
        }
    }

    # Series parsing
    $series = ""
    $sequence = ""
    if ($metadata.seriesName) {
        $rawSeries = $metadata.seriesName
        if ($rawSeries -match '^(.*?)\s*#\s*(\S+.*)$') {
            $series = $matches[1].Trim()
            $sequence = $matches[2].Trim()
        } else {
            $series = $rawSeries.Trim()
        }
    }

    $genres = if ($metadata.genres) { ($metadata.genres -join ", ") } else { "" }
    $durationSec = if ($item.media.duration) { [double]$item.media.duration } else { 0 }
    $formattedDuration = Format-DurationSeconds $durationSec

    $record = [PSCustomObject]@{
        Title          = $title
        Subtitle       = $subtitle
        Series         = $series
        SeriesSequence = $sequence
        Author         = $author
        Narrator       = $narrator
        Genres         = $genres
        ASIN           = $asin
        Duration       = $formattedDuration
        DurationSec    = $durationSec
        Id             = $item.id
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

Write-Host "  Loaded $canonicalCount canonical records ($($asinLookup.Count) unique ASINs)." -ForegroundColor Green

# 2. Filesystem Crawl & Discovery
Write-Host "[2/4] Crawling filesystem: $OrganizedAudiobooksPath" -ForegroundColor Yellow
$rootDirInfo = [System.IO.DirectoryInfo]::new("\\?\$OrganizedAudiobooksPath")
if (-not $rootDirInfo.Exists) {
    throw "Target directory not found: $OrganizedAudiobooksPath"
}

$audioExts = @('.m4b', '.mp3', '.m4a', '.flac', '.aac', '.wav', '.wma')
$catalogEntries = [System.Collections.Generic.List[PSCustomObject]]::new()

# Identify Media Base Root for Relative Paths
$mediaBase = Split-Path -Path $OrganizedAudiobooksPath -Parent

$dirQueue = [System.Collections.Generic.Queue[System.IO.DirectoryInfo]]::new()
$dirQueue.Enqueue($rootDirInfo)

$visitedBookDirs = [System.Collections.Generic.HashSet[string]]::new()

while ($dirQueue.Count -gt 0) {
    $currentDir = $dirQueue.Dequeue()

    try {
        $subDirs = @($currentDir.GetDirectories())
    } catch {
        Write-Warning "Could not access subdirectories of: $($currentDir.FullName)"
        continue
    }

    try {
        $files = @($currentDir.GetFiles())
    } catch {
        Write-Warning "Could not access files of: $($currentDir.FullName)"
        continue
    }

    $audioFiles = @($files | Where-Object { $audioExts -contains $_.Extension.ToLower() })
    $discSubdirs = @($subDirs | Where-Object { $_.Name -match '^(cd|disc|part)\s*\d+$' })

    # Check for loose multi-book directory (e.g. Audible with multiple independent .m4b files)
    $hasMultipleIndependentM4bs = $false
    if ($audioFiles.Count -gt 1 -and $currentDir.Name -eq "Audible") {
        $hasMultipleIndependentM4bs = $true
    }

    if ($hasMultipleIndependentM4bs) {
        # Process each audio file as an independent catalog entry
        foreach ($audioFile in $audioFiles) {
            $fileName = $audioFile.Name
            $fileExt = $audioFile.Extension.ToLower()
            $fileSizeMB = [Math]::Round($audioFile.Length / 1MB, 2)
            $cleanPath = $audioFile.FullName.Replace("\\?\", "")
            $relPath = $cleanPath.Substring($mediaBase.Length).TrimStart('\', '/')

            # Match metadata
            $matchedRecord = $null
            $asin = ""

            if ($fileName -match '\[([B0-9A-Z]{10})\]' -or $fileName -match '_([B0-9A-Z]{10})_') {
                $asin = $matches[1].ToUpper()
                if ($asinLookup.ContainsKey($asin)) {
                    $matchedRecord = $asinLookup[$asin]
                }
            }

            if ($null -eq $matchedRecord) {
                $normName = Clean-NormalizedString ([System.IO.Path]::GetFileNameWithoutExtension($fileName))
                foreach ($key in $titleAuthorLookup.Keys) {
                    if ($key.Length -ge 6 -and $normName.Contains($key)) {
                        $matchedRecord = $titleAuthorLookup[$key]
                        break
                    }
                }
            }

            if ($matchedRecord) {
                $entry = [PSCustomObject]@{
                    Title            = $matchedRecord.Title
                    Subtitle         = $matchedRecord.Subtitle
                    Series           = $matchedRecord.Series
                    'Series Sequence' = $matchedRecord.SeriesSequence
                    Author           = $matchedRecord.Author
                    Narrator         = $matchedRecord.Narrator
                    'Genre(s)'       = $matchedRecord.Genres
                    ASIN             = if ($matchedRecord.ASIN) { $matchedRecord.ASIN } else { $asin }
                    Duration         = $matchedRecord.Duration
                    'File Format'    = $fileExt
                    'Total Size (MB)' = $fileSizeMB
                    'Disk Path'      = $relPath
                    Status           = "Verified Original"
                }
            } else {
                $titleFall = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
                $entry = [PSCustomObject]@{
                    Title            = $titleFall
                    Subtitle         = ""
                    Series           = ""
                    'Series Sequence' = ""
                    Author           = "Unknown"
                    Narrator         = ""
                    'Genre(s)'       = ""
                    ASIN             = $asin
                    Duration         = ""
                    'File Format'    = $fileExt
                    'Total Size (MB)' = $fileSizeMB
                    'Disk Path'      = $relPath
                    Status           = "Uncataloged Asset"
                }
            }
            $catalogEntries.Add($entry)
        }
        
        # Still enqueue subdirectories of Audible (e.g. Converted)
        foreach ($sub in $subDirs) {
            $dirQueue.Enqueue($sub)
        }
        continue
    }

    # Standard book folder detection:
    # 1. Folder contains audio files directly and was not already visited
    # 2. Folder contains disc subdirectories (CD1, CD2) with audio files
    $isBookFolder = $false
    $bookAudioFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    $totalBookBytes = 0

    if ($audioFiles.Count -gt 0) {
        $isBookFolder = $true
        foreach ($af in $audioFiles) { $bookAudioFiles.Add($af) }
        $totalBookBytes = ($files | Measure-Object -Property Length -Sum).Sum
    } elseif ($discSubdirs.Count -gt 0) {
        # Check if disc subdirectories contain audio files
        foreach ($dsub in $discSubdirs) {
            try {
                $dFiles = @($dsub.GetFiles())
                $dAudio = @($dFiles | Where-Object { $audioExts -contains $_.Extension.ToLower() })
                if ($dAudio.Count -gt 0) {
                    $isBookFolder = $true
                    foreach ($daf in $dAudio) { $bookAudioFiles.Add($daf) }
                    $totalBookBytes += ($dFiles | Measure-Object -Property Length -Sum).Sum
                }
            } catch {}
        }
    }

    if ($isBookFolder) {
        $folderName = $currentDir.Name
        $cleanPath = $currentDir.FullName.Replace("\\?\", "")
        $relPath = $cleanPath.Substring($mediaBase.Length).TrimStart('\', '/')
        
        # Primary format
        $primaryFormat = ($bookAudioFiles | Group-Object Extension | Sort-Object Count -Descending | Select-Object -First 1).Name.ToLower()
        $totalSizeMB = [Math]::Round($totalBookBytes / 1MB, 2)

        # Metadata matching
        $matchedRecord = $null
        $asin = ""

        # Step A: ASIN match from folder name
        if ($folderName -match '\[([B0-9A-Z]{10})\]' -or $folderName -match '_([B0-9A-Z]{10})_') {
            $asin = $matches[1].ToUpper()
            if ($asinLookup.ContainsKey($asin)) {
                $matchedRecord = $asinLookup[$asin]
            }
        }

        # Step B: ASIN match from audio files inside folder
        if ($null -eq $matchedRecord) {
            foreach ($baf in $bookAudioFiles) {
                if ($baf.Name -match '\[([B0-9A-Z]{10})\]' -or $baf.Name -match '_([B0-9A-Z]{10})_') {
                    $asin = $matches[1].ToUpper()
                    if ($asinLookup.ContainsKey($asin)) {
                        $matchedRecord = $asinLookup[$asin]
                        break
                    }
                }
            }
        }

        # Step C: Title / Author normalized match
        if ($null -eq $matchedRecord) {
            $normFolderName = Clean-NormalizedString $folderName
            foreach ($key in $titleAuthorLookup.Keys) {
                if ($key.Length -ge 6 -and $normFolderName.Contains($key)) {
                    $matchedRecord = $titleAuthorLookup[$key]
                    break
                }
            }
        }

        if ($matchedRecord) {
            $entry = [PSCustomObject]@{
                Title            = $matchedRecord.Title
                Subtitle         = $matchedRecord.Subtitle
                Series           = $matchedRecord.Series
                'Series Sequence' = $matchedRecord.SeriesSequence
                Author           = $matchedRecord.Author
                Narrator         = $matchedRecord.Narrator
                'Genre(s)'       = $matchedRecord.Genres
                ASIN             = if ($matchedRecord.ASIN) { $matchedRecord.ASIN } else { $asin }
                Duration         = $matchedRecord.Duration
                'File Format'    = $primaryFormat
                'Total Size (MB)' = $totalSizeMB
                'Disk Path'      = $relPath
                Status           = "Verified Original"
            }
        } else {
            # Parse fallback author and series from path hierarchy
            $pathParts = $relPath.Split([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
            # Path layout: Organized Audiobooks \ Author \ [Series] \ Title [ASIN]
            $fallbackAuthor = "Unknown"
            $fallbackSeries = ""
            $fallbackSeq = ""

            if ($pathParts.Length -ge 2 -and $pathParts[1] -ne "_Uncataloged") {
                $fallbackAuthor = $pathParts[1]
                if ($pathParts.Length -ge 4) {
                    $rawSeries = $pathParts[2]
                    if ($rawSeries -ne "[Standalone Books]") {
                        if ($rawSeries -match '^(.*?)\s*#\s*(\S+.*)$') {
                            $fallbackSeries = $matches[1].Trim()
                            $fallbackSeq = $matches[2].Trim()
                        } else {
                            $fallbackSeries = $rawSeries.Trim()
                        }
                    }
                }
            } elseif ($pathParts.Length -ge 3 -and $pathParts[1] -eq "_Uncataloged") {
                $fallbackAuthor = $pathParts[2]
            }

            $cleanTitle = $folderName -replace '\s*\[[B0-9A-Z]{10}\]', ''
            $entry = [PSCustomObject]@{
                Title            = $cleanTitle.Trim()
                Subtitle         = ""
                Series           = $fallbackSeries
                'Series Sequence' = $fallbackSeq
                Author           = $fallbackAuthor
                Narrator         = ""
                'Genre(s)'       = ""
                ASIN             = $asin
                Duration         = ""
                'File Format'    = $primaryFormat
                'Total Size (MB)' = $totalSizeMB
                'Disk Path'      = $relPath
                Status           = "Uncataloged Asset"
            }
        }

        $catalogEntries.Add($entry)
        $visitedBookDirs.Add($cleanPath) | Out-Null

        # If this folder had disc subdirectories, we do not enqueue disc subdirs
        if ($discSubdirs.Count -gt 0 -and $discSubdirs.Count -eq $subDirs.Count) {
            continue
        }
    }

    # Enqueue subdirectories for deeper traversal
    foreach ($sub in $subDirs) {
        if (-not $discSubdirs.Contains($sub)) {
            $dirQueue.Enqueue($sub)
        }
    }
}

Write-Host "  Discovered $($catalogEntries.Count) total audiobook items." -ForegroundColor Green

# 3. Sort & Export Master Catalog
Write-Host "[3/4] Sorting and formatting master spreadsheet catalog..." -ForegroundColor Yellow
$sortedEntries = @($catalogEntries | Sort-Object Author, Series, 'Series Sequence', Title)

$outDir = [System.IO.Path]::GetDirectoryName($OutputCsvPath)
if (-not [System.IO.Directory]::Exists("\\?\$outDir")) {
    [System.IO.Directory]::CreateDirectory("\\?\$outDir") | Out-Null
}

$sortedEntries | Export-Csv -LiteralPath "\\?\$OutputCsvPath" -NoTypeInformation -Encoding UTF8
Write-Host "[4/4] Master Media Catalog successfully written to: $OutputCsvPath" -ForegroundColor Green

# 4. Summary Metrics
$verifiedCount = @($sortedEntries | Where-Object { $_.Status -eq "Verified Original" }).Count
$uncatalogedCount = @($sortedEntries | Where-Object { $_.Status -eq "Uncataloged Asset" }).Count
$totalSizeSumMB = ($sortedEntries | Measure-Object -Property 'Total Size (MB)' -Sum).Sum

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  CATALOG GENERATION SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Total Catalog Entries : $($sortedEntries.Count)" -ForegroundColor White
Write-Host "  Verified Originals    : $verifiedCount" -ForegroundColor Green
Write-Host "  Uncataloged Assets    : $uncatalogedCount" -ForegroundColor Yellow
Write-Host "  Total Indexed Size    : $([Math]::Round($totalSizeSumMB / 1024, 2)) GB ($([Math]::Round($totalSizeSumMB, 2)) MB)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan

return $sortedEntries
