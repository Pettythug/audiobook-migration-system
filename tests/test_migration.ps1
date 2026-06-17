$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
$uniqueId = [guid]::NewGuid().ToString().Substring(0,8)
$testDir = Join-Path -Path $scriptDir -ChildPath "MockMigration_$uniqueId"
$sourceDir = Join-Path -Path $testDir -ChildPath "Source"
$destDir = Join-Path -Path $testDir -ChildPath "Destination"
$csvPath = Join-Path -Path $testDir -ChildPath "migration_report.csv"

try {
    New-Item -ItemType Directory -Path $sourceDir -Force | Out-Null
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null

    # Create folders
    $bookA = Join-Path $sourceDir "Book A [PENDING]"
    $bookB = Join-Path $sourceDir "Book B [SYNCED]"
    $bookC = Join-Path $sourceDir "Book C [PENDING]"
    
    New-Item -ItemType Directory -Path $bookA -Force | Out-Null
    New-Item -ItemType Directory -Path $bookB -Force | Out-Null
    New-Item -ItemType Directory -Path $bookC -Force | Out-Null

    # Create mock files
    Set-Content -LiteralPath (Join-Path $bookA "file1.txt") -Value "content"
    Set-Content -LiteralPath (Join-Path $bookB "file2.txt") -Value "content"
    Set-Content -LiteralPath (Join-Path $bookC "file3.txt") -Value "content"

    # Create CSV
    $csvContent = @"
LocalFolder,Status
Book A [PENDING],[PENDING UPLOAD]
Book B [SYNCED],[SYNCED]
Book C [PENDING],[PENDING UPLOAD]
"@
    Set-Content -LiteralPath $csvPath -Value $csvContent

    # Run script
    $scriptPath = Join-Path -Path $scriptDir -ChildPath "Migrate-Audiobooks.ps1"
    & $scriptPath -ReportCsvPath $csvPath -SourceRoot $sourceDir -DestinationRoot $destDir

    # Assertions
    $bookAExists = Test-Path -LiteralPath (Join-Path $destDir "Book A [PENDING]")
    $bookBExists = Test-Path -LiteralPath (Join-Path $destDir "Book B [SYNCED]")
    $bookCExists = Test-Path -LiteralPath (Join-Path $destDir "Book C [PENDING]")

    if ($bookAExists -and -not $bookBExists -and $bookCExists) {
        Write-Host "TEST PASSED: Only pending audiobooks were migrated." -ForegroundColor Green
        exit 0
    } else {
        Write-Error "TEST FAILED: Incorrect migration behavior. BookA:$bookAExists BookB:$bookBExists BookC:$bookCExists"
        exit 1
    }
} catch {
    Write-Error "TEST FAILED WITH EXCEPTION: $_"
    exit 1
}
