<#
.SYNOPSIS
    Unit & Integration Test Suite for Generate-MediaCatalog.ps1

.DESCRIPTION
    Builds a temporary mock audiobook directory structure, generates mock metadata,
    executes Generate-MediaCatalog.ps1, and asserts 100% compliance with catalog specifications.
#>
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  TEST SUITE: Master Catalog Generator" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$testRoot = Join-Path -Path $env:TEMP -ChildPath "CatalogTest_$([guid]::NewGuid().ToString().Substring(0, 8))"
$mockJsonPath = Join-Path -Path $testRoot -ChildPath "mock_library.json"
$mockMediaRoot = Join-Path -Path $testRoot -ChildPath "04_Media"
$mockOrganized = Join-Path -Path $mockMediaRoot -ChildPath "Organized Audiobooks"
$mockOutputCsv = Join-Path -Path $mockMediaRoot -ChildPath "Media_Master_Catalog.csv"

[System.IO.Directory]::CreateDirectory($mockOrganized) | Out-Null

try {
    # 1. Create Mock Library JSON
    $mockLibrary = @{
        results = @(
            @{
                id = "mock-1"
                mediaType = "book"
                path = "D:/Audio Books/Book One [B000000001]"
                media = @{
                    metadata = @{
                        title = "Book One"
                        subtitle = "Origins"
                        authorName = "Brandon Sanderson"
                        narratorName = "Michael Kramer"
                        seriesName = "The Way of Kings #1"
                        genres = @("Fantasy", "Epic")
                        asin = "B000000001"
                    }
                    duration = 3661.5 # 1h 1m 1s -> 01:01:01
                    size = 10485760 # 10 MB
                    numTracks = 1
                }
            },
            @{
                id = "mock-2"
                mediaType = "book"
                path = "D:/Audio Books/Book Two [B000000002]"
                media = @{
                    metadata = @{
                        title = "Book Two"
                        subtitle = "Words of Radiance"
                        authorName = "Brandon Sanderson"
                        narratorName = "Kate Reading"
                        seriesName = "The Way of Kings #2"
                        genres = @("Fantasy", "Epic")
                        asin = "B000000002"
                    }
                    duration = 7200 # 2h -> 02:00:00
                    size = 20971520 # 20 MB
                    numTracks = 2
                }
            },
            @{
                id = "mock-3"
                mediaType = "book"
                path = "D:/Audio Books/Loose Audible Book [B000000003]"
                media = @{
                    metadata = @{
                        title = "Loose Audible Book"
                        subtitle = ""
                        authorName = "Arthur Conan Doyle"
                        narratorName = "Stephen Fry"
                        seriesName = ""
                        genres = @("Mystery")
                        asin = "B000000003"
                    }
                    duration = 1800 # 30m -> 00:30:00
                    size = 5242880 # 5 MB
                    numTracks = 1
                }
            }
        )
    }
    $mockLibrary | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $mockJsonPath -Encoding UTF8

    # 2. Build Mock Directory Tree
    # Book 1: Standard canonical layout
    $b1Path = Join-Path -Path $mockOrganized -ChildPath "Brandon Sanderson\The Way of Kings #1\Book One [B000000001]"
    [System.IO.Directory]::CreateDirectory($b1Path) | Out-Null
    [System.IO.File]::WriteAllBytes((Join-Path $b1Path "track.m4b"), [byte[]]::new(1048576)) # 1MB
    [System.IO.File]::WriteAllBytes((Join-Path $b1Path "cover.jpg"), [byte[]]::new(1024))

    # Book 2: Multi-disc layout
    $b2Path = Join-Path -Path $mockOrganized -ChildPath "Brandon Sanderson\The Way of Kings #2\Book Two [B000000002]"
    $cd1Path = Join-Path -Path $b2Path -ChildPath "CD 1"
    $cd2Path = Join-Path -Path $b2Path -ChildPath "CD 2"
    [System.IO.Directory]::CreateDirectory($cd1Path) | Out-Null
    [System.IO.Directory]::CreateDirectory($cd2Path) | Out-Null
    [System.IO.File]::WriteAllBytes((Join-Path $cd1Path "track01.mp3"), [byte[]]::new(1048576))
    [System.IO.File]::WriteAllBytes((Join-Path $cd2Path "track02.mp3"), [byte[]]::new(1048576))

    # Book 3: Loose Audible file
    $audiblePath = Join-Path -Path $mockOrganized -ChildPath "Audible"
    [System.IO.Directory]::CreateDirectory($audiblePath) | Out-Null
    [System.IO.File]::WriteAllBytes((Join-Path $audiblePath "Sherlock_B000000003_LC.m4b"), [byte[]]::new(2097152))
    [System.IO.File]::WriteAllBytes((Join-Path $audiblePath "Unmatched_Book_B099999999_LC.m4b"), [byte[]]::new(1048576))

    # Book 4: Uncataloged asset
    $uncatPath = Join-Path -Path $mockOrganized -ChildPath "_Uncataloged\Unknown Author\Some Indie Book"
    [System.IO.Directory]::CreateDirectory($uncatPath) | Out-Null
    [System.IO.File]::WriteAllBytes((Join-Path $uncatPath "audiobook.mp3"), [byte[]]::new(1048576))

    Write-Host "Mock test environment successfully configured." -ForegroundColor Green

    # 3. Execute Generate-MediaCatalog.ps1
    $engineScript = "C:\Users\wance\Documents\Git\audiobook-migration-system\src\Generate-MediaCatalog.ps1"
    $results = & $engineScript -LibraryJsonPath $mockJsonPath -OrganizedAudiobooksPath $mockOrganized -OutputCsvPath $mockOutputCsv

    # 4. Assertions
    $assertionsPassed = 0
    $totalAssertions = 8

    # Assert 1: Output CSV exists
    if (Test-Path -LiteralPath $mockOutputCsv) {
        Write-Host "[PASS] Assert 1: Output CSV file was successfully generated." -ForegroundColor Green
        $assertionsPassed++
    } else {
        Write-Error "[FAIL] Assert 1: Output CSV file was not found."
    }

    # Assert 2: Row count (Expecting 5 items: Book 1, Book 2, Loose B3, Loose B999, Uncat 4)
    $csvData = @(Import-Csv -LiteralPath $mockOutputCsv)
    if ($csvData.Count -eq 5) {
        Write-Host "[PASS] Assert 2: Catalog row count is exactly 5 ($($csvData.Count) detected)." -ForegroundColor Green
        $assertionsPassed++
    } else {
        Write-Error "[FAIL] Assert 2: Expected 5 catalog rows, but found $($csvData.Count)."
    }

    # Assert 3: Schema headers
    $expectedHeaders = @("Title", "Subtitle", "Series", "Series Sequence", "Author", "Narrator", "Genre(s)", "ASIN", "Duration", "File Format", "Total Size (MB)", "Disk Path", "Status")
    $firstRowHeaders = ($csvData[0].PSObject.Properties | Select-Object -ExpandProperty Name)
    $headerMatch = $true
    foreach ($h in $expectedHeaders) {
        if ($firstRowHeaders -notcontains $h) {
            $headerMatch = $false
            Write-Error "[FAIL] Header missing: $h"
        }
    }
    if ($headerMatch) {
        Write-Host "[PASS] Assert 3: All 13 master schema headers are present and aligned." -ForegroundColor Green
        $assertionsPassed++
    }

    # Assert 4: Duration formatting
    $b1Row = $csvData | Where-Object { $_.ASIN -eq "B000000001" }
    if ($b1Row.Duration -eq "01:01:01") {
        Write-Host "[PASS] Assert 4: Duration correctly formatted as 01:01:01 for Book One." -ForegroundColor Green
        $assertionsPassed++
    } else {
        Write-Error "[FAIL] Assert 4: Expected duration 01:01:01, found '$($b1Row.Duration)'."
    }

    # Assert 5: Verified Status count
    $verified = @($csvData | Where-Object { $_.Status -eq "Verified Original" })
    if ($verified.Count -eq 3) {
        Write-Host "[PASS] Assert 5: Exactly 3 books categorized as 'Verified Original'." -ForegroundColor Green
        $assertionsPassed++
    } else {
        Write-Error "[FAIL] Assert 5: Expected 3 Verified Original, found $($verified.Count)."
    }

    # Assert 6: Uncataloged Status count
    $uncat = @($csvData | Where-Object { $_.Status -eq "Uncataloged Asset" })
    if ($uncat.Count -eq 2) {
        Write-Host "[PASS] Assert 6: Exactly 2 books categorized as 'Uncataloged Asset'." -ForegroundColor Green
        $assertionsPassed++
    } else {
        Write-Error "[FAIL] Assert 6: Expected 2 Uncataloged Asset, found $($uncat.Count)."
    }

    # Assert 7: Disc rollup verification
    $b2Row = $csvData | Where-Object { $_.ASIN -eq "B000000002" }
    if ($b2Row.'Total Size (MB)' -ge 2.0 -and $b2Row.'Disk Path' -notmatch 'CD\s*\d+') {
        Write-Host "[PASS] Assert 7: Disc subdirectories rolled up into parent book directory." -ForegroundColor Green
        $assertionsPassed++
    } else {
        Write-Error "[FAIL] Assert 7: Disc rollup failed or size incorrect ($($b2Row.'Total Size (MB)') MB)."
    }

    # Assert 8: Series Sequence extraction
    if ($b1Row.'Series Sequence' -eq "1" -and $b2Row.'Series Sequence' -eq "2") {
        Write-Host "[PASS] Assert 8: Series sequences ('1' and '2') extracted correctly." -ForegroundColor Green
        $assertionsPassed++
    } else {
        Write-Error "[FAIL] Assert 8: Series sequence extraction mismatch."
    }

    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "  TEST RESULTS: $assertionsPassed / $totalAssertions PASSED (100%)" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan
}
finally {
    # Clean up mock directory
    if (Test-Path -LiteralPath $testRoot) {
        [System.IO.Directory]::Delete($testRoot, $true)
    }
}
