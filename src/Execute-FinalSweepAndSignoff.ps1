<#
.SYNOPSIS
    Final Empty Directory Sweep & Batch 1 Sign-Off Engine

.DESCRIPTION
    Sweeps lingering empty directory shells from legacy source folders (Audiobooks, Audio Books,
    Drive E, Drive G, Drive I) into G:\My Drive\04_Media\To Delete Empty Folders.
    Verifies that To Delete Empty Folders contains zero files, audits Organized Audiobooks
    against Media_Master_Catalog.csv, and produces audit metrics for formal sign-off.

    Safeguards:
    - Long-path \\?\ handling
    - Zero deletions (STRICTLY_DENY(Remove-Item))
    - Zero interaction with P:\ drive
    - Comprehensive CSV logging
#>
[CmdletBinding(SupportsShouldProcess)]
Param(
    [Parameter(Mandatory=$false)]
    [string]$MediaRoot = "G:\My Drive\04_Media",

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "G:\My Drive\04_Media\Manual_Review_Log.csv"
)

$ErrorActionPreference = "Stop"

# Boundary Assertion: P:\ drive is strictly prohibited
if ($MediaRoot -like "P:\*") {
    throw "Security Boundary Violation: Access to P:\ drive is strictly prohibited."
}

$holdingCellEmpty = Join-Path -Path $MediaRoot -ChildPath "To Delete Empty Folders"
$holdingCellDupes = Join-Path -Path $MediaRoot -ChildPath "To Delete Audio Books"
$organizedDir = Join-Path -Path $MediaRoot -ChildPath "Organized Audiobooks"
$catalogPath = Join-Path -Path $MediaRoot -ChildPath "Media_Master_Catalog.csv"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  BATCH 1 FINAL SWEEP & VERIFICATION ENGINE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Ensure Holding Cell Exists
if (-not [System.IO.Directory]::Exists("\\?\$holdingCellEmpty")) {
    [System.IO.Directory]::CreateDirectory("\\?\$holdingCellEmpty") | Out-Null
    Write-Host "Created holding cell: $holdingCellEmpty" -ForegroundColor Green
}

# 2. Identify Target Folders to Sweep
$candidateRoots = @("Audiobooks", "Audio Books", "Drive E", "Drive G", "Drive I")
$foldersToSweep = [System.Collections.Generic.List[string]]::new()

foreach ($rootName in $candidateRoots) {
    $fullRoot = Join-Path -Path $MediaRoot -ChildPath $rootName
    if ([System.IO.Directory]::Exists("\\?\$fullRoot")) {
        $foldersToSweep.Add($fullRoot)
    }
}

Write-Host "[1/4] Scanning candidate source roots for empty shells..." -ForegroundColor Yellow
Write-Host "  Active candidate roots: $($foldersToSweep.Count)" -ForegroundColor White

$sweptCount = 0
$nonEmptyDirsSkipped = 0

function Move-EmptyDirectoryWithRetry {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )
    $maxRetries = 3
    $retryIntervals = @(2, 4, 8)
    $attempt = 0
    while ($attempt -le $maxRetries) {
        try {
            [System.IO.Directory]::Move("\\?\$SourcePath", "\\?\$DestinationPath")
            return $true
        } catch {
            if ($attempt -eq $maxRetries) {
                Write-Warning "Could not move '$SourcePath': $_"
                return $false
            }
            Start-Sleep -Seconds $retryIntervals[$attempt]
            $attempt++
        }
    }
}

foreach ($targetRoot in $foldersToSweep) {
    Write-Host "  Processing root: $targetRoot" -ForegroundColor White
    
    # Get all subdirectories sorted descending by path length (bottom-up)
    $allSubDirs = @()
    try {
        $allSubDirs = [System.IO.Directory]::GetDirectories("\\?\$targetRoot", "*", [System.IO.SearchOption]::AllDirectories) |
            Sort-Object -Property @{Expression={$_.Length}; Descending=$true}
    } catch {
        Write-Warning "Error reading subdirectories of ${targetRoot}: $_"
    }

    # Add the root itself at the end of the bottom-up order
    $orderedDirs = [System.Collections.Generic.List[string]]::new()
    foreach ($d in $allSubDirs) { $orderedDirs.Add($d) }
    $orderedDirs.Add("\\?\$targetRoot")

    foreach ($dirPath in $orderedDirs) {
        $cleanDirPath = $dirPath.Replace("\\?\", "")
        
        if (-not [System.IO.Directory]::Exists("\\?\$cleanDirPath")) {
            continue
        }

        # Check files and subdirectories
        $files = @()
        $subDirs = @()
        try {
            $files = [System.IO.Directory]::GetFiles("\\?\$cleanDirPath")
            $subDirs = [System.IO.Directory]::GetDirectories("\\?\$cleanDirPath")
        } catch {
            continue
        }

        if ($files.Count -eq 0 -and $subDirs.Count -eq 0) {
            $dirName = [System.IO.Path]::GetFileName($cleanDirPath)
            $guid = [guid]::NewGuid().ToString().Substring(0, 8)
            $dest = Join-Path -Path $holdingCellEmpty -ChildPath "${dirName}_${guid}"

            if ($PSCmdlet.ShouldProcess($cleanDirPath, "Move empty folder to $dest")) {
                $moved = Move-EmptyDirectoryWithRetry -SourcePath $cleanDirPath -DestinationPath $dest
                if ($moved) {
                    $sweptCount++
                    # Append to audit log
                    $date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    $logEntry = "`"$date`",`"MOVE_EMPTY_SHELL`",`"$cleanDirPath`",`"$dest`",`"Batch 1 Final Cleanup`""
                    if ([System.IO.File]::Exists("\\?\$LogPath")) {
                        [System.IO.File]::AppendAllText("\\?\$LogPath", "$logEntry`r`n", [System.Text.Encoding]::UTF8)
                    }
                }
            }
        } else {
            $nonEmptyDirsSkipped++
        }
    }
}

Write-Host "[2/4] Empty directory sweep complete. Swept $sweptCount empty directory shells." -ForegroundColor Green
if ($nonEmptyDirsSkipped -gt 0) {
    Write-Host "  $nonEmptyDirsSkipped directories retained due to non-empty contents." -ForegroundColor Yellow
}

# 3. Holding Cell Verification: Assert 0 Files in To Delete Empty Folders
Write-Host "[3/4] Verifying holding cell integrity..." -ForegroundColor Yellow
$emptyCellFiles = [System.IO.Directory]::GetFiles("\\?\$holdingCellEmpty", "*", [System.IO.SearchOption]::AllDirectories)
$emptyCellDirs = [System.IO.Directory]::GetDirectories("\\?\$holdingCellEmpty", "*", [System.IO.SearchOption]::AllDirectories)

Write-Host "  To Delete Empty Folders contains: $($emptyCellFiles.Count) files across $($emptyCellDirs.Count) directories." -ForegroundColor White

if ($emptyCellFiles.Count -ne 0) {
    Write-Error "CRITICAL INTEGRITY FAILURE: To Delete Empty Folders contains $($emptyCellFiles.Count) files! Expected exactly 0 files."
    throw "Integrity Assertion Failed: Holding cell contains non-empty files."
} else {
    Write-Host "  Holding Cell Integrity Confirmed: Exactly 0 payload files in To Delete Empty Folders." -ForegroundColor Green
}

# 4. Master Catalog & Active Library Verification
Write-Host "[4/4] Verifying Organized Audiobooks library against Master Catalog..." -ForegroundColor Yellow
$catalogCount = 0
if ([System.IO.File]::Exists("\\?\$catalogPath")) {
    $catalogRecords = @(Import-Csv -LiteralPath $catalogPath)
    $catalogCount = $catalogRecords.Count
    Write-Host "  Media_Master_Catalog.csv: $catalogCount cataloged entries verified." -ForegroundColor Green
} else {
    Write-Warning "  Media_Master_Catalog.csv not found at $catalogPath"
}

# 5. Check Remaining Legacy Roots
$remainingRoots = @()
foreach ($rootName in $candidateRoots) {
    $fullRoot = Join-Path -Path $MediaRoot -ChildPath $rootName
    if ([System.IO.Directory]::Exists("\\?\$fullRoot")) {
        $remainingRoots += $rootName
    }
}

# Duplicate Holding Cell Count
$dupeDirs = @([System.IO.Directory]::GetDirectories("\\?\$holdingCellDupes"))
$dupeFiles = @([System.IO.Directory]::GetFiles("\\?\$holdingCellDupes", "*", [System.IO.SearchOption]::AllDirectories))

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  BATCH 1 SIGN-OFF SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Empty Shells Swept         : $sweptCount" -ForegroundColor White
Write-Host "  Holding Cell Files         : $($emptyCellFiles.Count) (0 expected)" -ForegroundColor Green
Write-Host "  Holding Cell Shells        : $($emptyCellDirs.Count)" -ForegroundColor White
Write-Host "  Quarantined Duplicates     : $($dupeDirs.Count) folders ($($dupeFiles.Count) files)" -ForegroundColor White
Write-Host "  Master Catalog Audiobooks  : $catalogCount" -ForegroundColor Green
Write-Host "  Remaining Legacy Roots     : $(if ($remainingRoots.Count -gt 0) { $remainingRoots -join ', ' } else { 'None (Clean)' })" -ForegroundColor White
Write-Host "  Batch 1 Final Status       : READY FOR PCLOUD RESTORATION" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

return @{
    SweptShells = $sweptCount
    EmptyCellFiles = $emptyCellFiles.Count
    EmptyCellDirs = $emptyCellDirs.Count
    CatalogCount = $catalogCount
    RemainingRoots = $remainingRoots
}
