$ErrorActionPreference = "Stop"

$TestRoot = Join-Path -Path $env:TEMP -ChildPath "SweeperTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
$MockTarget = Join-Path -Path $TestRoot -ChildPath "MockTarget"
$MockHolding = Join-Path -Path $TestRoot -ChildPath "MockHolding"

try {
    # 1. Setup Mock Tree
    New-Item -Path $MockTarget -ItemType Directory -Force | Out-Null
    New-Item -Path $MockHolding -ItemType Directory -Force | Out-Null

    # PopulatedFolder
    $Populated = Join-Path $MockTarget "PopulatedFolder"
    New-Item -Path $Populated -ItemType Directory | Out-Null
    Set-Content -Path (Join-Path $Populated "file1.txt") -Value "test"

    # EmptyFolderA
    New-Item -Path (Join-Path $MockTarget "EmptyFolderA") -ItemType Directory | Out-Null

    # EmptyFolderB and EmptyFolderC
    $EmptyB = Join-Path $MockTarget "EmptyFolderB"
    New-Item -Path $EmptyB -ItemType Directory | Out-Null
    New-Item -Path (Join-Path $EmptyB "EmptyFolderC") -ItemType Directory | Out-Null

    # MixedFolder
    $Mixed = Join-Path $MockTarget "MixedFolder"
    New-Item -Path $Mixed -ItemType Directory | Out-Null
    New-Item -Path (Join-Path $Mixed "EmptyFolderD") -ItemType Directory | Out-Null
    $Pop2 = Join-Path $Mixed "PopulatedFolder2"
    New-Item -Path $Pop2 -ItemType Directory | Out-Null
    Set-Content -Path (Join-Path $Pop2 "file2.txt") -Value "test"

    # 2. Run Sweeper
    & .\src\Clean-EmptyDirectories.ps1 -TargetDirectory $MockTarget -HoldingCellDirectory $MockHolding

    # 3. Assertions
    $Failed = $false

    # Assert Files are untouched
    if (-not (Test-Path (Join-Path $Populated "file1.txt"))) {
        Write-Error "file1.txt was deleted or moved!"
        $Failed = $true
    }
    if (-not (Test-Path (Join-Path $Pop2 "file2.txt"))) {
        Write-Error "file2.txt was deleted or moved!"
        $Failed = $true
    }

    # Assert Empty Folders are moved
    if (Test-Path (Join-Path $MockTarget "EmptyFolderA")) {
        Write-Error "EmptyFolderA was not moved out of Target!"
        $Failed = $true
    }
    if (Test-Path (Join-Path $MockTarget "EmptyFolderB")) {
        Write-Error "EmptyFolderB was not moved out of Target!"
        $Failed = $true
    }
    if (Test-Path (Join-Path $MockTarget "MixedFolder\EmptyFolderD")) {
        Write-Error "EmptyFolderD was not moved out of Target!"
        $Failed = $true
    }

    # Assert Empty Folders exist in Holding Cell
    # Note: Since they were all moved to the root of Holding Cell, they should exist there.
    if (-not (Test-Path (Join-Path $MockHolding "EmptyFolderA"))) {
        Write-Error "EmptyFolderA is missing from Holding Cell!"
        $Failed = $true
    }
    if (-not (Test-Path (Join-Path $MockHolding "EmptyFolderC"))) {
        Write-Error "EmptyFolderC is missing from Holding Cell!"
        $Failed = $true
    }
    if (-not (Test-Path (Join-Path $MockHolding "EmptyFolderB"))) {
        Write-Error "EmptyFolderB is missing from Holding Cell!"
        $Failed = $true
    }

    if (-not $Failed) {
        Write-Host "Test Passed Successfully!"
    } else {
        Write-Error "Test Failed!"
    }
} finally {
    # Cleanup
    if (Test-Path $TestRoot) {
        Remove-Item -Path $TestRoot -Recurse -Force
    }
}
