$ErrorActionPreference = "Stop"

$checks = @(
    @{ Name = 'PyCharm'; Path = 'G:\My Drive\02_Projects\PyCharm'; ExpectedFiles = 38717; ExpectedDirs = 6769 },
    @{ Name = 'Rackspace'; Path = 'G:\My Drive\02_Projects\Rackspace'; ExpectedFiles = 1175; ExpectedDirs = 160 },
    @{ Name = 'Workout Stuff'; Path = 'G:\My Drive\03_Personal\Workout Stuff'; ExpectedFiles = 18; ExpectedDirs = 2 }
)

Write-Host "=== TASK-011 Destination Verification ===" -ForegroundColor Cyan

$allMatched = $true
$results = foreach ($c in $checks) {
    $p = $c.Path
    $exists = Test-Path -LiteralPath "\\?\$p"
    if (-not $exists) {
        $allMatched = $false
        [PSCustomObject]@{
            Name = $c.Name
            Exists = $false
            Files = 0
            ExpectedFiles = $c.ExpectedFiles
            FilesMatch = $false
            Dirs = 0
            ExpectedDirs = $c.ExpectedDirs
            DirsMatch = $false
        }
    } else {
        $f = (Get-ChildItem -LiteralPath "\\?\$p" -Recurse -File -Force).Count
        $d = (Get-ChildItem -LiteralPath "\\?\$p" -Recurse -Directory -Force).Count
        $fMatch = ($f -eq $c.ExpectedFiles)
        $dMatch = ($d -eq $c.ExpectedDirs)
        if (-not $fMatch -or -not $dMatch) { $allMatched = $false }
        [PSCustomObject]@{
            Name = $c.Name
            Exists = $true
            Files = $f
            ExpectedFiles = $c.ExpectedFiles
            FilesMatch = $fMatch
            Dirs = $d
            ExpectedDirs = $c.ExpectedDirs
            DirsMatch = $dMatch
        }
    }
}

$results | Format-Table -AutoSize

Write-Host "=== Source Drain Verification ===" -ForegroundColor Cyan
$sourcePath = "G:\My Drive\04_Media\Drive G\To Delete Empty Folders"
$remainingItems = Get-ChildItem -LiteralPath "\\?\$sourcePath" -Force
$remainingCount = ($remainingItems | Measure-Object).Count
Write-Host "Remaining items in '$sourcePath': $remainingCount" -ForegroundColor Yellow
if ($remainingCount -gt 0) {
    $remainingItems | Select-Object Name, Mode | Format-Table -AutoSize
}

Write-Host "Overall Verification Status: $(if ($allMatched -and $remainingCount -eq 0) { 'SUCCESS (100% Match & Drained)' } else { 'FAIL' })"
