$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

$MockRoot = Join-Path $ProjectRoot "mock_env_prestage"
$MockSourceBase = Join-Path $MockRoot "04_Media\Drive G\To Delete Empty Folders"
$MockProjects = Join-Path $MockRoot "02_Projects"
$MockPersonal = Join-Path $MockRoot "03_Personal"
$MockRepoLog = Join-Path $MockRoot "repo_log.csv"
$MockMediaLog = Join-Path $MockRoot "media_log.csv"

if (Test-Path -LiteralPath "\\?\$MockRoot") {
    Remove-Item -LiteralPath "\\?\$MockRoot" -Recurse -Force
}

# 1. Setup mock source structure
$mockPycharm = Join-Path $MockSourceBase "PyCharm"
$mockRackspace = Join-Path $MockSourceBase "Rackspace"
$mockWorkout = Join-Path $MockSourceBase "Workout Stuff"

[System.IO.Directory]::CreateDirectory("\\?\$mockPycharm\subfolder") | Out-Null
[System.IO.File]::WriteAllText("\\?\$mockPycharm\subfolder\test.py", "print('hello')")
[System.IO.File]::WriteAllText("\\?\$mockPycharm\config.xml", "<config></config>")

[System.IO.Directory]::CreateDirectory("\\?\$mockRackspace") | Out-Null
[System.IO.File]::WriteAllText("\\?\$mockRackspace\server.conf", "server=test")

[System.IO.Directory]::CreateDirectory("\\?\$mockWorkout") | Out-Null
[System.IO.File]::WriteAllText("\\?\$mockWorkout\routine.txt", "chest day")

"TargetFolder,Reason" | Out-File -LiteralPath "\\?\$MockRepoLog" -Encoding UTF8

$scriptPath = Join-Path $ProjectRoot "src\PreStage-NonMedia.ps1"

Write-Host "--- Test 1: Security Boundary Check (P:\ Drive Denied) ---" -ForegroundColor Yellow
$boundaryPassed = $false
try {
    & $scriptPath -SourceBase "P:\Forbidden" -ProjectsTarget $MockProjects -PersonalTarget $MockPersonal
} catch {
    if ($_ -match "Security Boundary Violation") {
        $boundaryPassed = $true
        Write-Host "PASS: Boundary check properly threw error for P:\ access." -ForegroundColor Green
    }
}
if (-not $boundaryPassed) {
    throw "FAIL: Boundary check failed to prevent P:\ access!"
}

Write-Host "--- Test 2: Dry-Run Simulation (-WhatIf) ---" -ForegroundColor Yellow
& $scriptPath -SourceBase $MockSourceBase -ProjectsTarget $MockProjects -PersonalTarget $MockPersonal -RepoLogPath $MockRepoLog -MediaLogPath $MockMediaLog -WhatIf

if (-not (Test-Path -LiteralPath "\\?\$mockPycharm\subfolder\test.py")) {
    throw "FAIL: WhatIf simulation modified source files!"
}
if (Test-Path -LiteralPath "\\?\$MockProjects\PyCharm") {
    throw "FAIL: WhatIf simulation created target files!"
}
Write-Host "PASS: -WhatIf executed safely without side-effects." -ForegroundColor Green

Write-Host "--- Test 3: Live Execution ---" -ForegroundColor Yellow
& $scriptPath -SourceBase $MockSourceBase -ProjectsTarget $MockProjects -PersonalTarget $MockPersonal -RepoLogPath $MockRepoLog -MediaLogPath $MockMediaLog

if (-not (Test-Path -LiteralPath "\\?\$MockProjects\PyCharm\subfolder\test.py")) {
    throw "FAIL: PyCharm was not relocated to 02_Projects!"
}
if (-not (Test-Path -LiteralPath "\\?\$MockProjects\Rackspace\server.conf")) {
    throw "FAIL: Rackspace was not relocated to 02_Projects!"
}
if (-not (Test-Path -LiteralPath "\\?\$MockPersonal\Workout Stuff\routine.txt")) {
    throw "FAIL: Workout Stuff was not relocated to 03_Personal!"
}
if (Test-Path -LiteralPath "\\?\$mockPycharm") {
    throw "FAIL: Source PyCharm was not removed after move!"
}
Write-Host "PASS: Live relocation succeeded and verified." -ForegroundColor Green

Write-Host "--- Test 4: Verify Logging ---" -ForegroundColor Yellow
$mediaLogContent = Get-Content -LiteralPath "\\?\$MockMediaLog"
$repoLogContent = Get-Content -LiteralPath "\\?\$MockRepoLog"

if ($mediaLogContent.Count -lt 4) { # Header + 3 lines
    throw "FAIL: Media log missing entries!"
}
if ($repoLogContent.Count -lt 4) { # Header + 3 lines
    throw "FAIL: Repo log missing entries!"
}
Write-Host "PASS: Both log files correctly recorded 3 relocations." -ForegroundColor Green

# Cleanup
Remove-Item -LiteralPath "\\?\$MockRoot" -Recurse -Force
Write-Host "=== ALL TESTS PASSED (100% Pass Rate) ===" -ForegroundColor Green
