$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

$MockDir = Join-Path $ProjectRoot "mock_env"
$TargetDir = Join-Path $MockDir "Organized Audiobooks"
$HoldingCell = Join-Path $MockDir "To Delete Audio Books"
$LogPath = Join-Path $MockDir "Manual_Review_Log.csv"
$JsonPath = Join-Path $MockDir "mock_library.json"

if (Test-Path "\\?\$MockDir") { Remove-Item "\\?\$MockDir" -Recurse -Force }

New-Item -ItemType Directory -Path "\\?\$TargetDir" -Force | Out-Null
New-Item -ItemType Directory -Path "\\?\$HoldingCell" -Force | Out-Null

$mockData = @"
{
  "results": [
    {
      "mediaType": "book",
      "id": "1",
      "media": {
        "metadata": {
          "title": "The Way of Kings",
          "authorName": "Brandon Sanderson",
          "seriesName": "The Stormlight Archive",
          "asin": "B003ZWFO7E"
        },
        "numTracks": 1,
        "size": 1000
      }
    },
    {
      "mediaType": "book",
      "id": "2",
      "media": {
        "metadata": {
          "title": "Project Hail Mary",
          "authorName": "Andy Weir",
          "seriesName": "",
          "asin": "B08G9NJCGG"
        },
        "numTracks": 1,
        "size": 500
      }
    }
  ]
}
"@
Set-Content -Path $JsonPath -Value $mockData -Encoding UTF8

$b1Path = Join-Path $TargetDir "The Way of Kings [B003ZWFO7E]"
New-Item -ItemType Directory -Path "\\?\$b1Path" -Force | Out-Null
New-Item -ItemType File -Path "\\?\$b1Path\01 - track.mp3" -Value "test" -Force | Out-Null

$b2Path = Join-Path $TargetDir "The Way of Kings Duplicate"
New-Item -ItemType Directory -Path "\\?\$b2Path" -Force | Out-Null
New-Item -ItemType File -Path "\\?\$b2Path\01 - track.mp3" -Value "test short" -Force | Out-Null

$b3Path = Join-Path $TargetDir "Unknown Fantasy Book"
New-Item -ItemType Directory -Path "\\?\$b3Path" -Force | Out-Null
New-Item -ItemType File -Path "\\?\$b3Path\01 - track.mp3" -Value "test" -Force | Out-Null

$b4Path = Join-Path $TargetDir "Project Hail Mary [B08G9NJCGG]"
New-Item -ItemType Directory -Path "\\?\$b4Path" -Force | Out-Null
New-Item -ItemType File -Path "\\?\$b4Path\01 - track.mp3" -Value "test" -Force | Out-Null

$deepPath = $TargetDir
for ($i=0; $i -lt 15; $i++) { $deepPath = Join-Path $deepPath "NestedFolder_1234567890" }
$b5Path = Join-Path $deepPath "Some Nested Audio"
New-Item -ItemType Directory -Path "\\?\$b5Path" -Force | Out-Null
New-Item -ItemType File -Path "\\?\$b5Path\audio.mp3" -Value "test" -Force | Out-Null

$scriptPath = Join-Path $ProjectRoot "src\Reorganize-AudiobookshelfManifest.ps1"
& $scriptPath -LibraryJsonPath $JsonPath -TargetDirectory $TargetDir -HoldingCellDirectory $HoldingCell

$errors = 0

$expectedKings = "\\?\$TargetDir\Brandon Sanderson\The Stormlight Archive\The Way of Kings [B003ZWFO7E]"
if (-not (Test-Path -LiteralPath $expectedKings)) { Write-Host "FAIL: The Way of Kings not found"; $errors++ }

$expectedHailMary = "\\?\$TargetDir\Andy Weir\[Standalone Books]\Project Hail Mary [B08G9NJCGG]"
if (-not (Test-Path -LiteralPath $expectedHailMary)) { Write-Host "FAIL: Project Hail Mary not found"; $errors++ }

$duplicateHolding = "\\?\$HoldingCell\The Way of Kings Duplicate"
if (-not (Test-Path -LiteralPath $duplicateHolding)) { Write-Host "FAIL: Duplicate not found in Holding Cell"; $errors++ }

$expectedUncataloged = "\\?\$TargetDir\_Uncataloged\Unknown Fantasy Book"
if (-not (Test-Path -LiteralPath $expectedUncataloged)) { Write-Host "FAIL: Uncataloged not found in _Uncataloged"; $errors++ }

$deepUncataloged = "\\?\$TargetDir\_Uncataloged\Some Nested Audio"
if (-not (Test-Path -LiteralPath $deepUncataloged)) { Write-Host "FAIL: Deeply nested uncataloged not moved correctly"; $errors++ }

if (-not (Test-Path -LiteralPath "\\?\$LogPath")) { Write-Host "FAIL: Manual_Review_Log.csv not created"; $errors++ }

if ($errors -eq 0) {
    Write-Host "ALL TESTS PASSED (100% Pass)" -ForegroundColor Green
} else {
    Write-Host "TESTS FAILED ($errors errors)" -ForegroundColor Red
    exit 1
}

if (Test-Path "\\?\$MockDir") { Remove-Item "\\?\$MockDir" -Recurse -Force }
