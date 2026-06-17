param (
    [Parameter(Mandatory=$true)]
    [string]$TargetDirectory,
    [Parameter(Mandatory=$true)]
    [string]$PCloudManifestPath,
    [Parameter(Mandatory=$true)]
    [string]$GDriveManifestPath,
    [Parameter(Mandatory=$false)]
    [string]$ReportOutputPath = "migration_report.csv"
)
function Get-CleanTitle {
    param([string]$Title)
    try {
        # Extract leaf if path
        $leaf = Split-Path $Title -Leaf
        if (-not $leaf) { $leaf = $Title }
        
        # Remove [ID] tags and trim whitespace
        $clean = $leaf -replace '\[.*?\]', ''
        return $clean.Trim()
    } catch {
        return $Title
    }
}
try {
    if (-not (Test-Path -LiteralPath $TargetDirectory -PathType Container)) {
        throw "Target directory not found: $TargetDirectory"
    }
    if (-not (Test-Path -LiteralPath $PCloudManifestPath -PathType Leaf)) {
        throw "PCloud manifest not found: $PCloudManifestPath"
    }
    if (-not (Test-Path -LiteralPath $GDriveManifestPath -PathType Leaf)) {
        throw "GDrive manifest not found: $GDriveManifestPath"
    }
    $pcloud = Import-Csv -LiteralPath $PCloudManifestPath
    $gdrive = Import-Csv -LiteralPath $GDriveManifestPath
    $manifestTitles = @{}
    if ($pcloud) {
        foreach ($row in $pcloud) {
            $clean = Get-CleanTitle -Title $row.highest_common_parent
            if (![string]::IsNullOrWhiteSpace($clean)) {
                $manifestTitles[$clean.ToLower()] = $true
            }
        }
    }
    if ($gdrive) {
        foreach ($row in $gdrive) {
            $clean = Get-CleanTitle -Title $row.highest_common_parent
            if (![string]::IsNullOrWhiteSpace($clean)) {
                $manifestTitles[$clean.ToLower()] = $true
            }
        }
    }
    $localFolders = Get-ChildItem -LiteralPath $TargetDirectory -Directory
    $results = @()
    foreach ($folder in $localFolders) {
        $cleanFolderName = Get-CleanTitle -Title $folder.Name
        
        $status = "[PENDING UPLOAD]"
        if (![string]::IsNullOrWhiteSpace($cleanFolderName) -and $manifestTitles.ContainsKey($cleanFolderName.ToLower())) {
            $status = "[SYNCED]"
        }
        
        $results += [PSCustomObject]@{
            LocalFolder = $folder.Name
            CleanTitle  = $cleanFolderName
            Status      = $status
        }
    }
    $results | Export-Csv -LiteralPath $ReportOutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Manifest comparison completed successfully. Report exported to $ReportOutputPath"
}
catch {
    Write-Error "An error occurred during file I/O or processing: $_"
    exit 1
}
