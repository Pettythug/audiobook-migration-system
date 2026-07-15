Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Define a unique test root directory in TEMP
$TestRoot = Join-Path $env:TEMP "AudiobookConsolidateTest_$(Get-Random)"
New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null

$ScriptPath = Join-Path $PSScriptRoot "../src/Consolidate-AudioBooks.ps1"
$AllPassed = $true

function Reset-MockEnvironment {
    if (Test-Path -LiteralPath $TestRoot) {
        Remove-Item -LiteralPath $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null

    # Create mock source directories
    $SourceDirs = @()
    foreach ($Drive in @("DriveI", "DriveE", "DriveG")) {
        $Path = Join-Path $TestRoot $Drive
        $SourceDirs += $Path
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        
        # Add normal audiobook folders
        $Book1 = Join-Path $Path "Book_${Drive}_1"
        New-Item -ItemType Directory -Path $Book1 -Force | Out-Null
        "audio" | Out-File -LiteralPath (Join-Path $Book1 "chapter1.mp3") -Encoding utf8
        
        $Book2 = Join-Path $Path "Book_${Drive}_2"
        New-Item -ItemType Directory -Path $Book2 -Force | Out-Null
        "audio" | Out-File -LiteralPath (Join-Path $Book2 "chapter1.m4b") -Encoding utf8

        # Add excluded folders
        New-Item -ItemType Directory -Path (Join-Path $Path "To Delete Audio Books") -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $Path "To Delete Empty Folders") -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $Path ".git") -Force | Out-Null
    }

    # Create mock destination directory
    $DestDir = Join-Path $TestRoot "OrganizedAudiobooks"
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null

    return @($SourceDirs, $DestDir)
}

try {
    # ----------------------------------------------------
    # TEST 1: Normal execution
    # ----------------------------------------------------
    Write-Host "Running Test 1: Normal execution..."
    $Env = Reset-MockEnvironment
    $SourceDirs = $Env[0]
    $DestDir = $Env[1]

    & $ScriptPath -SourceDirectories $SourceDirs -DestinationDirectory $DestDir

    # Assertions for Test 1
    foreach ($Src in $SourceDirs) {
        $DriveName = Split-Path $Src -Leaf
        
        # Check if normal books were moved
        $Book1Path = Join-Path $Src "Book_${DriveName}_1"
        $Book2Path = Join-Path $Src "Book_${DriveName}_2"
        if (Test-Path -LiteralPath $Book1Path) {
            Write-Error "Test 1 Failed: Book_${DriveName}_1 was not moved from source."
            $AllPassed = $false
        }
        if (Test-Path -LiteralPath $Book2Path) {
            Write-Error "Test 1 Failed: Book_${DriveName}_2 was not moved from source."
            $AllPassed = $false
        }

        # Check if they exist in destination
        $DestBook1 = Join-Path $DestDir "Book_${DriveName}_1"
        $DestBook2 = Join-Path $DestDir "Book_${DriveName}_2"
        if (-not (Test-Path -LiteralPath $DestBook1)) {
            Write-Error "Test 1 Failed: Book_${DriveName}_1 does not exist in destination."
            $AllPassed = $false
        }
        if (-not (Test-Path -LiteralPath $DestBook2)) {
            Write-Error "Test 1 Failed: Book_${DriveName}_2 does not exist in destination."
            $AllPassed = $false
        }

        # Check that excluded folders were NOT moved
        if (-not (Test-Path -LiteralPath (Join-Path $Src "To Delete Audio Books"))) {
            Write-Error "Test 1 Failed: 'To Delete Audio Books' was incorrectly moved or deleted."
            $AllPassed = $false
        }
        if (-not (Test-Path -LiteralPath (Join-Path $Src "To Delete Empty Folders"))) {
            Write-Error "Test 1 Failed: 'To Delete Empty Folders' was incorrectly moved or deleted."
            $AllPassed = $false
        }
        if (-not (Test-Path -LiteralPath (Join-Path $Src ".git"))) {
            Write-Error "Test 1 Failed: '.git' was incorrectly moved or deleted."
            $AllPassed = $false
        }
    }

    # ----------------------------------------------------
    # TEST 2: WhatIf parameter execution
    # ----------------------------------------------------
    Write-Host "Running Test 2: WhatIf dry-run execution..."
    $Env = Reset-MockEnvironment
    $SourceDirs = $Env[0]
    $DestDir = $Env[1]

    # Run with -WhatIf
    & $ScriptPath -SourceDirectories $SourceDirs -DestinationDirectory $DestDir -WhatIf

    # Assertions for Test 2: nothing should have changed
    foreach ($Src in $SourceDirs) {
        $DriveName = Split-Path $Src -Leaf
        $Book1Path = Join-Path $Src "Book_${DriveName}_1"
        $Book2Path = Join-Path $Src "Book_${DriveName}_2"
        
        if (-not (Test-Path -LiteralPath $Book1Path)) {
            Write-Error "Test 2 Failed: Book_${DriveName}_1 was moved under -WhatIf."
            $AllPassed = $false
        }
        if (-not (Test-Path -LiteralPath $Book2Path)) {
            Write-Error "Test 2 Failed: Book_${DriveName}_2 was moved under -WhatIf."
            $AllPassed = $false
        }

        # Destination should not have these books
        $DestBook1 = Join-Path $DestDir "Book_${DriveName}_1"
        $DestBook2 = Join-Path $DestDir "Book_${DriveName}_2"
        if (Test-Path -LiteralPath $DestBook1) {
            Write-Error "Test 2 Failed: Book_${DriveName}_1 exists in destination under -WhatIf."
            $AllPassed = $false
        }
        if (Test-Path -LiteralPath $DestBook2) {
            Write-Error "Test 2 Failed: Book_${DriveName}_2 exists in destination under -WhatIf."
            $AllPassed = $false
        }
    }

    # ----------------------------------------------------
    # TEST 3: Name collision handling
    # ----------------------------------------------------
    Write-Host "Running Test 3: Name collision handling..."
    $Env = Reset-MockEnvironment
    $SourceDirs = $Env[0]
    $DestDir = $Env[1]

    # Pre-create a folder with the same name in the destination
    $CollisionName = "Book_DriveI_1"
    $DestCollisionPath = Join-Path $DestDir $CollisionName
    New-Item -ItemType Directory -Path $DestCollisionPath -Force | Out-Null
    "old_content" | Out-File -LiteralPath (Join-Path $DestCollisionPath "info.txt") -Encoding utf8

    & $ScriptPath -SourceDirectories $SourceDirs -DestinationDirectory $DestDir

    # Assertions for Test 3
    # The original collision path in destination should still have old_content
    if (-not (Test-Path -LiteralPath (Join-Path $DestCollisionPath "info.txt"))) {
        Write-Error "Test 3 Failed: Original destination folder was overwritten or deleted."
        $AllPassed = $false
    }

    # A new version with timestamp should have been created
    $MovedCollisionFolders = @(Get-ChildItem -LiteralPath $DestDir -Directory -Filter "${CollisionName}_*")
    if ($MovedCollisionFolders.Count -ne 1) {
        Write-Error "Test 3 Failed: Colliding folder was not renamed with a timestamp. Found: $($MovedCollisionFolders.Count) matches."
        $AllPassed = $false
    } else {
        $TimestampFolder = $MovedCollisionFolders[0].FullName
        if (-not (Test-Path -LiteralPath (Join-Path $TimestampFolder "chapter1.mp3"))) {
            Write-Error "Test 3 Failed: Colliding folder content was not moved to the timestamped folder."
            $AllPassed = $false
        }
    }

    if ($AllPassed) {
        Write-Host "All tests passed 100%!" -ForegroundColor Green
    } else {
        Write-Error "One or more tests failed."
    }

} finally {
    # Clean up test root
    if (Test-Path -LiteralPath $TestRoot) {
        Remove-Item -LiteralPath $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Test cleanup complete."
}
