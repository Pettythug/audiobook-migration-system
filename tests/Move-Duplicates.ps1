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
# Resolve the TargetDirectory to an absolute path
$TargetDirectory = (Resolve-Path $TargetDirectory).Path
$toDeleteDir = Join-Path -Path $TargetDirectory -ChildPath "To Delete Audio Books"
# Ensure the staging directory exists
if (-not (Test-Path $toDeleteDir)) {
    New-Item -ItemType Directory -Force -Path $toDeleteDir | Out-Null
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
# We only consider directories that are NOT inside the 'To Delete Audio Books' staging folder
$escapedToDelete = [regex]::Escape("To Delete Audio Books")
$directoriesWithFiles = $files | Where-Object { $_.DirectoryName -notmatch $escapedToDelete } | Select-Object -ExpandProperty DirectoryName -Unique
$newTitles = @()
$duplicatesMoved = @()
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
        # It's a duplicate, move it to the To Delete Audio Books directory
        $destPath = Join-Path -Path $toDeleteDir -ChildPath (Split-Path $dir -Leaf)
        
        # Move the entire directory non-destructively
        Move-Item -Path $dir -Destination $destPath -Force
        $duplicatesMoved += $mappedPath
    } else {
        $newTitles += $mappedPath
    }
}
Write-Host "========== Migration Results =========="
Write-Host ""
Write-Host "--- Moved to 'To Delete Audio Books' (Duplicates) ---"
if ($duplicatesMoved.Count -eq 0) { Write-Host "None" }
foreach ($title in $duplicatesMoved) {
    Write-Host " - $title"
}
Write-Host ""
Write-Host "--- Left in Place (New Titles) ---"
if ($newTitles.Count -eq 0) { Write-Host "None" }
foreach ($title in $newTitles) {
    Write-Host " + $title"
}
