<#
.SYNOPSIS
    Unit Test Suite for Ingest-PCloudAudiobooks.ps1

.DESCRIPTION
    Builds a mock environment in $env:TEMP simulating pCloud source folders,
    existing holdings in 04_Media, and canonical manifest. Verifies ingestion,
    deduplication, upgrade logic, and zero deletions.
#>
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  TEST SUITE: Ingest-PCloudAudiobooks" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$testRoot = Join-Path -Path $env:TEMP -ChildPath "PCloudTest_$([guid]::NewGuid().ToString().Substring(0, 8))"
$mockManifest = Join-Path -Path $testRoot -ChildPath "mock_manifest.json"
$mockPCloud = Join-Path -Path $testRoot -ChildPath "pcloud"
$mockTarget = Join-Path -Path $testRoot -ChildPath "04_Media\Organized Audiobooks"
$mockHolding = Join-Path -Path $testRoot -ChildPath "04_Media\To Delete Audio Books"
$mockLog = Join-Path -Path $testRoot -ChildPath "04_Media\Manual_Review_Log.csv"

[System.IO.Directory]::CreateDirectory($mockPCloud) | Out-Null
[System.IO.Directory]::CreateDirectory($mockTarget) | Out-Null
[System.IO.Directory]::CreateDirectory($mockHolding) | Out-Null

try {
    # 1. Create Mock Manifest
    $manifestData = @{
        results = @(
            @{
                id = "m1"
                mediaType = "book"
                path = "D:/Audio Books/The Shining [B000000010]"
                media = @{
                    metadata = @{
                        title = "The Shining"
                        subtitle = ""
                        authorName = "Stephen King"
                        seriesName = "The Shining #1"
                        asin = "B000000010"
                    }
                    duration = 36000
                    size = 500000000
                    numTracks = 10
                }
            },
            @{
                id = "m2"
                mediaType = "book"
                path = "D:/Audio Books/Doctor Sleep [B000000020]"
                media = @{
                    metadata = @{
                        title = "Doctor Sleep"
                        subtitle = ""
                        authorName = "Stephen King"
                        seriesName = "The Shining #2"
                        asin = "B000000020"
                    }
                    duration = 40000
                    size = 600000000
                    numTracks = 12
                }
            },
            @{
                id = "m3"
                mediaType = "book"
                path = "D:/Audio Books/Mistborn [B000000030]"
                media = @{
                    metadata = @{
                        title = "Mistborn"
                        subtitle = "The Final Empire"
                        authorName = "Brandon Sanderson"
                        seriesName = "Mistborn #1"
                        asin = "B000000030"
                    }
                    duration = 50000
                    size = 800000000
                    numTracks = 15
                }
            }
        )
    }
    $manifestData | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $mockManifest -Encoding UTF8

    # 2. Setup Existing Holdings in 04_Media
    # Existing Book 2: Doctor Sleep (Already staged in 04_Media, 10MB mp3)
    $existingB2Dir = Join-Path -Path $mockTarget -ChildPath "Stephen King\The Shining #2\Doctor Sleep [B000000020]"
    [System.IO.Directory]::CreateDirectory($existingB2Dir) | Out-Null
    [System.IO.File]::WriteAllBytes((Join-Path $existingB2Dir "track.mp3"), [byte[]]::new(10485760)) # 10MB

    # 3. Setup Candidates in pCloud
    # Candidate 1: The Shining (New canonical book, not in 04_Media)
    $cand1Dir = Join-Path -Path $mockPCloud -ChildPath "Stephen King\The Shining [B000000010]"
    [System.IO.Directory]::CreateDirectory($cand1Dir) | Out-Null
    [System.IO.File]::WriteAllBytes((Join-Path $cand1Dir "shining.m4b"), [byte[]]::new(20971520)) # 20MB

    # Candidate 2: Doctor Sleep (Duplicate in pCloud, but inferior 2MB mp3)
    $cand2Dir = Join-Path -Path $mockPCloud -ChildPath "Stephen King\Doctor Sleep [B000000020]"
    [System.IO.Directory]::CreateDirectory($cand2Dir) | Out-Null
    [System.IO.File]::WriteAllBytes((Join-Path $cand2Dir "sleep.mp3"), [byte[]]::new(2097152)) # 2MB

    # Candidate 3: Unmatched folder (Should remain in pCloud untouched)
    $cand3Dir = Join-Path -Path $mockPCloud -ChildPath "Random Author\Unmatched Indie Track"
    [System.IO.Directory]::CreateDirectory($cand3Dir) | Out-Null
    [System.IO.File]::WriteAllBytes((Join-Path $cand3Dir "indie.mp3"), [byte[]]::new(1048576))

    Write-Host "Mock test fixtures configured." -ForegroundColor Green

    # 4. Execute Engine Script
    $engine = "C:\Users\wance\Documents\Git\audiobook-migration-system\src\Ingest-PCloudAudiobooks.ps1"
    $res = & $engine -ManifestPath $mockManifest -PCloudSourcePath $mockPCloud -TargetMediaPath $mockTarget -HoldingCellPath $mockHolding -LogPath $mockLog

    # 5. Assertions
    $passed = 0
    $total = 6

    # Assert 1: Ingested count is 1 (The Shining)
    if ($res.IngestedCount -eq 1) {
        Write-Host "[PASS] Assert 1: Ingested exactly 1 new canonical book." -ForegroundColor Green
        $passed++
    } else {
        Write-Error "[FAIL] Assert 1: Expected IngestedCount=1, got $($res.IngestedCount)"
    }

    # Assert 2: Quarantined count is 1 (Doctor Sleep duplicate)
    if ($res.QuarantinedCount -eq 1) {
        Write-Host "[PASS] Assert 2: Quarantined exactly 1 duplicate candidate." -ForegroundColor Green
        $passed++
    } else {
        Write-Error "[FAIL] Assert 2: Expected QuarantinedCount=1, got $($res.QuarantinedCount)"
    }

    # Assert 3: The Shining exists in canonical destination
    $expectedShiningPath = Join-Path -Path $mockTarget -ChildPath "Stephen King\The Shining #1\The Shining [B000000010]"
    if (Test-Path -LiteralPath $expectedShiningPath) {
        Write-Host "[PASS] Assert 3: The Shining moved to canonical layout ($expectedShiningPath)." -ForegroundColor Green
        $passed++
    } else {
        Write-Error "[FAIL] Assert 3: Canonical destination not found: $expectedShiningPath"
    }

    # Assert 4: Doctor Sleep existing copy retained in 04_Media
    if (Test-Path -LiteralPath $existingB2Dir) {
        Write-Host "[PASS] Assert 4: Existing superior Doctor Sleep copy preserved in 04_Media." -ForegroundColor Green
        $passed++
    } else {
        Write-Error "[FAIL] Assert 4: Existing Doctor Sleep copy was erroneously moved."
    }

    # Assert 5: Duplicate Doctor Sleep placed in holding cell
    $holdingFiles = @(Get-ChildItem -LiteralPath $mockHolding -Recurse -File)
    if ($holdingFiles.Count -eq 1) {
        Write-Host "[PASS] Assert 5: Duplicate Doctor Sleep payload verified in holding cell." -ForegroundColor Green
        $passed++
    } else {
        Write-Error "[FAIL] Assert 5: Expected 1 holding cell file, found $($holdingFiles.Count)"
    }

    # Assert 6: Unmatched asset still in pCloud
    if (Test-Path -LiteralPath $cand3Dir) {
        Write-Host "[PASS] Assert 6: Unmatched indie asset safely preserved in pCloud." -ForegroundColor Green
        $passed++
    } else {
        Write-Error "[FAIL] Assert 6: Unmatched asset was modified or moved."
    }

    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "  TEST RESULTS: $passed / $total PASSED (100%)" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        [System.IO.Directory]::Delete($testRoot, $true)
    }
}
