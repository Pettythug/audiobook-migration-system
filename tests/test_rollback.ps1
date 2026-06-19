$ErrorActionPreference = 'Stop'

$mockRoot = Join-Path $env:TEMP "RollbackTest_$(Get-Random)"
$masterDir = Join-Path $mockRoot "Master"
$targetDir = Join-Path $mockRoot "Target\pcloud"
$csvPath = Join-Path $mockRoot "Manual_Review_Log.csv"

Write-Host "Creating mock directories at $mockRoot"
New-Item -Path $masterDir -ItemType Directory -Force | Out-Null
New-Item -Path $targetDir -ItemType Directory -Force | Out-Null

# 1. Empty Shell
$emptyShellPath = Join-Path $targetDir "EmptyBook"
New-Item -Path $emptyShellPath -ItemType Directory -Force | Out-Null

# 2. Duplicate Book
$dupBookMaster = Join-Path $masterDir "DupBook"
$dupBookTarget = Join-Path $targetDir "DupBook"
New-Item -Path $dupBookMaster -ItemType Directory -Force | Out-Null
New-Item -Path $dupBookTarget -ItemType Directory -Force | Out-Null
Set-Content -Path (Join-Path $dupBookMaster "audio.mp3") -Value "Master content"
Set-Content -Path (Join-Path $dupBookTarget "audio.mp3") -Value "Target" # Smaller, so it's a duplicate

# Run Deduplicate
Write-Host "Running Deduplicate-CloudDrives.ps1"
$dedupScript = Resolve-Path "tests\Deduplicate-CloudDrives.ps1"

# Deduplicate-CloudDrives.ps1 creates LogFile in current directory. 
# We temporarily change dir to $mockRoot
Push-Location $mockRoot
try {
    & $dedupScript -MasterDirectory $masterDir -TargetDirectories @($targetDir)
} finally {
    Pop-Location
}

# The generated CSV will have paths like C:\Users\wance\AppData\Local\Temp\RollbackTest_...\Target\pcloud\EmptyBook
# We need to replace $targetDir with 'G:\My Drive\pcloud' so Rollback-CloudDrives.ps1 can process it.
Write-Host "Rewriting CSV paths to simulate G:\My Drive\pcloud"
$csvContent = Get-Content -Path $csvPath
$csvContent = $csvContent -replace [regex]::Escape($targetDir), 'G:\My Drive\pcloud'
Set-Content -Path $csvPath -Value $csvContent

Write-Host "CSV Contents:"
Get-Content -Path $csvPath

$rollbackScript = Resolve-Path "src\Rollback-CloudDrives.ps1"

Write-Host "`n--- Running Rollback-CloudDrives.ps1 with -WhatIf ---"
& $rollbackScript -TargetDrive $targetDir -CsvPath $csvPath -WhatIf

Write-Host "`n--- Running Rollback-CloudDrives.ps1 for REAL ---"
& $rollbackScript -TargetDrive $targetDir -CsvPath $csvPath

Write-Host "`n--- Asserting Results ---"
$emptyShellRestored = Test-Path -LiteralPath $emptyShellPath
$dupBookRestored = Test-Path -LiteralPath $dupBookTarget

$toDeleteEmpty = Join-Path $targetDir "To Delete Empty Folders"
$toDeleteBooks = Join-Path $targetDir "To Delete Audio Books"

$emptyStagingCount = 0
$booksStagingCount = 0
if (Test-Path $toDeleteEmpty) {
    $emptyStagingCount = @(Get-ChildItem -LiteralPath $toDeleteEmpty).Count
}
if (Test-Path $toDeleteBooks) {
    $booksStagingCount = @(Get-ChildItem -LiteralPath $toDeleteBooks).Count
}

Write-Host "emptyShellRestored: $emptyShellRestored"
Write-Host "dupBookRestored: $dupBookRestored"
Write-Host "emptyStagingCount: $emptyStagingCount"
Write-Host "booksStagingCount: $booksStagingCount"

if ($emptyShellRestored -and $dupBookRestored -and $emptyStagingCount -eq 0 -and $booksStagingCount -eq 0) {
    Write-Host "`nTEST PASSED"
} else {
    Write-Host "`nTEST FAILED"
    exit 1
}

Write-Host "Cleaning up $mockRoot"
Remove-Item -Path $mockRoot -Recurse -Force
