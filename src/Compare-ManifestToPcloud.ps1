<#
.SYNOPSIS
    Compares the GDrive manifest against the pcloud directory.

.DESCRIPTION
    This script reads gdrive_manifest.csv and scans the mock pcloud directory.
    It compares the child folder names in pcloud against the highest_common_parent column in the CSV.
    It outputs lists of missing and duplicate folders.
#>

[CmdletBinding()]
param (
    [string]$ManifestPath = 'c:\Users\wance\.gemini\antigravity\Organize Audio Books\gdrive_manifest.csv',
    [string]$PcloudPath = 'c:\Users\wance\.gemini\antigravity\Organize Audio Books\AudioBook_Migration_Project\tests\Mock_G_Drive\My Drive\pcloud'
)

try {
    Write-Output "Starting comparison process..."
    
    if (-not (Test-Path -Path $ManifestPath)) {
        throw "Manifest file not found at $ManifestPath"
    }
    
    if (-not (Test-Path -Path $PcloudPath)) {
        throw "pcloud directory not found at $PcloudPath"
    }

    # Read manifest
    $manifestData = Import-Csv -Path $ManifestPath
    $manifestParents = $manifestData | Select-Object -ExpandProperty highest_common_parent | Sort-Object -Unique
    
    # Get pcloud folders
    $pcloudFolders = Get-ChildItem -Path $PcloudPath -Directory | Select-Object -ExpandProperty Name
    
    $missingFromAudioBooks = @()
    $duplicatesFound = @()
    
    foreach ($folder in $pcloudFolders) {
        if ($manifestParents -contains $folder) {
            $duplicatesFound += $folder
        } else {
            $missingFromAudioBooks += $folder
        }
    }
    
    Write-Output "Missing from Audio Books (Unique to pcloud):"
    foreach ($item in $missingFromAudioBooks) {
        Write-Output " - $item"
    }
    
    Write-Output "Duplicates Found:"
    foreach ($item in $duplicatesFound) {
        Write-Output " - $item"
    }
    
    Write-Output "Comparison process completed successfully."

} catch {
    Write-Error "An error occurred during execution: $_"
}
