param (
    [Parameter(Mandatory=$true)]
    [string]$ManifestPath,
    [Parameter(Mandatory=$true)]
    [string]$TargetDirectory
)
# Ensure paths exist
if (-not (Test-Path $ManifestPath)) {
    Write-Error "Manifest file not found: $ManifestPath"
    exit 1
}
if (-not (Test-Path $TargetDirectory)) {
    Write-Error "Target directory not found: $TargetDirectory"
    exit 1
}
# Parse the CSV
$manifest = Import-Csv -Path $ManifestPath
# Create a hash set for faster lookups (case-insensitive for Windows paths)
$manifestPaths = @{}
foreach ($row in $manifest) {
    if (-not [string]::IsNullOrWhiteSpace($row.highest_common_parent)) {
        $manifestPaths[$row.highest_common_parent] = $true
    }
}
# Scan the target directory for directories containing files (assumed leaf directories/audiobook folders)
$files = Get-ChildItem -Path $TargetDirectory -Recurse -File
$directoriesWithFiles = $files | Select-Object -ExpandProperty DirectoryName -Unique
$newTitles = @()
$duplicates = @()
foreach ($dir in $directoriesWithFiles) {
    # Dynamically map the physical local paths to the manifest's expected format
    $mappedPath = ""
    $myDriveIndex = $dir.IndexOf("My Drive", [System.StringComparison]::OrdinalIgnoreCase)
    
    if ($myDriveIndex -ge 0) {
        $mappedPath = "G:\" + $dir.Substring($myDriveIndex)
    } else {
        # Fallback in case "My Drive" isn't in the path, though expected per task
        $mappedPath = $dir
    }
    if ($manifestPaths.ContainsKey($mappedPath)) {
        $duplicates += $mappedPath
    } else {
        $newTitles += $mappedPath
    }
}
Write-Host "========== Comparison Results =========="
Write-Host ""
Write-Host "--- New Titles (NOT in Manifest) ---"
if ($newTitles.Count -eq 0) { Write-Host "None" }
foreach ($title in $newTitles) {
    Write-Host " + $title"
}
Write-Host ""
Write-Host "--- Duplicates (ARE in Manifest) ---"
if ($duplicates.Count -eq 0) { Write-Host "None" }
foreach ($title in $duplicates) {
    Write-Host " - $title"
}
