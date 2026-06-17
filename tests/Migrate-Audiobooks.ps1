[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$ReportCsvPath,

    [Parameter(Mandatory=$true)]
    [string]$SourceRoot,

    [Parameter(Mandatory=$true)]
    [string]$DestinationRoot
)

try {
    if (-not (Test-Path -LiteralPath $ReportCsvPath)) {
        throw "CSV file not found at path: $ReportCsvPath"
    }

    if (-not (Test-Path -LiteralPath $DestinationRoot)) {
        try {
            New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null
        } catch {
            throw "Failed to create DestinationRoot: $_"
        }
    }

    $report = Import-Csv -LiteralPath $ReportCsvPath

    foreach ($row in $report) {
        if ($row.Status -eq "[PENDING UPLOAD]") {
            $localFolder = $row.LocalFolder
            $sourcePath = Join-Path -Path $SourceRoot -ChildPath $localFolder
            $destPath = Join-Path -Path $DestinationRoot -ChildPath $localFolder

            if (Test-Path -LiteralPath $sourcePath) {
                if (-not (Test-Path -LiteralPath $destPath)) {
                    try {
                        Copy-Item -LiteralPath $sourcePath -Destination $DestinationRoot -Recurse -Force
                        Write-Host "Successfully migrated: $localFolder"
                    } catch {
                        Write-Host "Failed to copy folder $localFolder : $_"
                    }
                } else {
                    Write-Host "Destination already exists for: $localFolder. Skipping."
                }
            } else {
                Write-Host "Source folder not found: $sourcePath"
            }
        } elseif ($row.Status -eq "[SYNCED]") {
            Write-Host "Skipping synced folder: $($row.LocalFolder)"
        }
    }
} catch {
    Write-Host "A fatal error occurred: $_"
}
