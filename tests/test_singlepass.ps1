$ErrorActionPreference = "Stop"

$TestDir = Join-Path -Path $PSScriptRoot -ChildPath "MockSinglePassTest"
if (Test-Path -LiteralPath $TestDir) {
    Remove-Item -LiteralPath $TestDir -Recurse -Force
}
New-Item -Path $TestDir -ItemType Directory | Out-Null

$MasterDir = Join-Path -Path $TestDir -ChildPath "Master"
$TargetDir = Join-Path -Path $TestDir -ChildPath "Target"
New-Item -Path $MasterDir -ItemType Directory | Out-Null
New-Item -Path $TargetDir -ItemType Directory | Out-Null

# Setup Master
$MasterBook1 = Join-Path -Path $MasterDir -ChildPath "The Great Gatsby [123]"
New-Item -Path $MasterBook1 -ItemType Directory | Out-Null
$MasterFile1 = Join-Path -Path $MasterBook1 -ChildPath "audio1.mp3"
"Large content string" | Out-File -LiteralPath $MasterFile1 -Encoding utf8

$MasterBook2 = Join-Path -Path $MasterDir -ChildPath "Dune [456]"
New-Item -Path $MasterBook2 -ItemType Directory | Out-Null
$MasterFile2 = Join-Path -Path $MasterBook2 -ChildPath "audio2.m4b"
"Small" | Out-File -LiteralPath $MasterFile2 -Encoding utf8

# Setup Target
# 1. Empty Shell
$TargetBook1 = Join-Path -Path $TargetDir -ChildPath "Empty Book [789]"
New-Item -Path $TargetBook1 -ItemType Directory | Out-Null
$TargetFile1 = Join-Path -Path $TargetBook1 -ChildPath "info.txt"
"No audio here" | Out-File -LiteralPath $TargetFile1 -Encoding utf8

# 2. Exact/Inferior Duplicate (Matches MasterBook1 but smaller)
$TargetBook2 = Join-Path -Path $TargetDir -ChildPath "The Great Gatsby [abc]"
New-Item -Path $TargetBook2 -ItemType Directory | Out-Null
$TargetFile2 = Join-Path -Path $TargetBook2 -ChildPath "audio.mp3"
"Tiny" | Out-File -LiteralPath $TargetFile2 -Encoding utf8

# 3. Target Superior (Matches MasterBook2 but larger)
$TargetBook3 = Join-Path -Path $TargetDir -ChildPath "Dune [def]"
New-Item -Path $TargetBook3 -ItemType Directory | Out-Null
$TargetFile3 = Join-Path -Path $TargetBook3 -ChildPath "audio.m4b"
"Very very very very very large content string here" | Out-File -LiteralPath $TargetFile3 -Encoding utf8

# Change directory to test dir to output log there
Push-Location -LiteralPath $TestDir

# Run script
& (Join-Path -Path $PSScriptRoot -ChildPath "Deduplicate-CloudDrives.ps1") -MasterDirectory $MasterDir -TargetDirectories @($TargetDir)

# Assertions
Write-Host "Running Assertions..."
$ToDeleteDir = Join-Path -Path $TargetDir -ChildPath "To Delete Audio Books"

# 1. Empty Shell moved
if (Test-Path -LiteralPath (Join-Path -Path $ToDeleteDir -ChildPath "Empty Book [789]")) {
    Write-Host "PASS: Empty Shell moved." -ForegroundColor Green
} else {
    Write-Host "FAIL: Empty Shell not moved." -ForegroundColor Red
}

# 2. Inferior Duplicate moved
if (Test-Path -LiteralPath (Join-Path -Path $ToDeleteDir -ChildPath "The Great Gatsby [abc]")) {
    Write-Host "PASS: Inferior Duplicate moved." -ForegroundColor Green
} else {
    Write-Host "FAIL: Inferior Duplicate not moved." -ForegroundColor Red
}

# 3. Superior Target NOT moved
if (Test-Path -LiteralPath (Join-Path -Path $TargetDir -ChildPath "Dune [def]")) {
    Write-Host "PASS: Superior Target retained." -ForegroundColor Green
} else {
    Write-Host "FAIL: Superior Target moved incorrectly." -ForegroundColor Red
}

$LogFile = "Manual_Review_Log.csv"
if (Test-Path -LiteralPath $LogFile) {
    Write-Host "PASS: Log file created." -ForegroundColor Green
    $LogContent = Get-Content -LiteralPath $LogFile
    if ($LogContent -match "Empty Book \[789\].*Empty Shell") {
        Write-Host "PASS: Logged Empty Shell correctly." -ForegroundColor Green
    }
    if ($LogContent -match "The Great Gatsby \[abc\].*Exact/Inferior Duplicate") {
        Write-Host "PASS: Logged Inferior Duplicate correctly." -ForegroundColor Green
    }
    if ($LogContent -match "Dune \[def\].*Target Superior") {
        Write-Host "PASS: Logged Target Superior correctly." -ForegroundColor Green
    }
} else {
    Write-Host "FAIL: Log file missing." -ForegroundColor Red
}

Pop-Location
# Clean up
Remove-Item -LiteralPath $TestDir -Recurse -Force
