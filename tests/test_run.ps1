$ErrorActionPreference = "Stop"

$testTarget = Join-Path -Path $PSScriptRoot -ChildPath "MockTarget"
if (Test-Path -LiteralPath $testTarget) {
    Remove-Item -LiteralPath $testTarget -Recurse -Force
}
New-Item -ItemType Directory -Path $testTarget | Out-Null

# 1. Apples-to-Apples
$aa1 = New-Item -ItemType Directory -Path (Join-Path $testTarget "Book A [123]")
$aa2 = New-Item -ItemType Directory -Path (Join-Path $testTarget "Book A [456]")
New-Item -ItemType File -Path (Join-Path $aa1.FullName "audio1.mp3") -Value "AUDIO" | Out-Null
New-Item -ItemType File -Path (Join-Path $aa2.FullName "audio1.mp3") -Value "AUDIO" | Out-Null

# 2. Empty Shell
$es1 = New-Item -ItemType Directory -Path (Join-Path $testTarget "Book B [789]")
$es2 = New-Item -ItemType Directory -Path (Join-Path $testTarget "Book B [abc]")
New-Item -ItemType File -Path (Join-Path $es1.FullName "audio1.mp3") -Value "AUDIO" | Out-Null
New-Item -ItemType File -Path (Join-Path $es2.FullName "cover.jpg") -Value "IMG" | Out-Null

# 3. Asymmetrical
$as1 = New-Item -ItemType Directory -Path (Join-Path $testTarget "Book C [xyz]")
$as2 = New-Item -ItemType Directory -Path (Join-Path $testTarget "Book C [def]")
New-Item -ItemType File -Path (Join-Path $as1.FullName "audio1.mp3") -Value "AUDIO" | Out-Null
New-Item -ItemType File -Path (Join-Path $as1.FullName "audio2.mp3") -Value "AUDIO2" | Out-Null
New-Item -ItemType File -Path (Join-Path $as2.FullName "audio1.mp3") -Value "AUDIO" | Out-Null

# Run the deduplicate script
Write-Host "Running Deduplication Script..."
& (Join-Path -Path $PSScriptRoot -ChildPath "Deduplicate-Audiobooks.ps1") -TargetDirectory $testTarget -LogFile (Join-Path $testTarget "Manual_Review_Log.csv")

# Verify
Write-Host "Verification Results:"
$deleteDir = Join-Path $testTarget "To Delete Audio Books"
if (Test-Path -LiteralPath $deleteDir) {
    $deleted = @(Get-ChildItem -LiteralPath $deleteDir -Directory)
    Write-Host "Deleted folders count: $($deleted.Count)"
    foreach ($d in $deleted) {
        Write-Host " - $($d.Name)"
    }
} else {
    Write-Host "Deleted folders count: 0"
}

$logFile = Join-Path $testTarget "Manual_Review_Log.csv"
if (Test-Path -LiteralPath $logFile) {
    Write-Host "Log Contents:"
    Get-Content -LiteralPath $logFile | Write-Host
} else {
    Write-Host "No log file created."
}
