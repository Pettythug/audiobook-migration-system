
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [string]$TargetDrive = "G:\My Drive\pcloud",

    [Parameter(Mandatory=$false)]
    [string]$CsvPath = "Manual_Review_Log.csv"
)

Set-StrictMode -Version Latest
# Initialize local variables (camelCase)
$originalPrefix = "G:\My Drive\pcloud"

# Verify CSV file existence and import
if (-not (Test-Path -LiteralPath $CsvPath)) {
    Throw "CSV file not found at path: $CsvPath"
}

try {
    $csvData = Import-Csv -LiteralPath $CsvPath -ErrorAction Stop
} catch {
    Throw "Failed to import CSV from '$CsvPath': $_"
}

foreach ($row in $csvData) {
    $targetFolder = $row.TargetFolder
    $reason = $row.Reason

    # Filter by specified criteria
    if ($reason -match "Empty Shell" -or $reason -match "Exact/Inferior Duplicate") {
        # Check if the path starts with the expected prefix
        if (-not $targetFolder.StartsWith($originalPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Error "TargetFolder '$targetFolder' in CSV does not start with expected prefix '$originalPrefix'."
            continue
        }

        # Resolve the relative path and build the destination target folder on TargetDrive
        $relativePath = $targetFolder.Substring($originalPrefix.Length)
        if ($relativePath.StartsWith("\") -or $relativePath.StartsWith("/")) {
            $relativePath = $relativePath.Substring(1)
        }
        $resolvedTargetFolder = Join-Path -Path $TargetDrive -ChildPath $relativePath

        # Determine the staging directory
        $stagingRootName = if ($reason -match "Empty Shell") {
            "To Delete Empty Folders"
        } else {
            "To Delete Audio Books"
        }
        $topLevelFolder = ($relativePath -split "[\\/]")[0]
        $stagingRoot = Join-Path -Path $TargetDrive -ChildPath $topLevelFolder
        $stagingRoot = Join-Path -Path $stagingRoot -ChildPath $stagingRootName

        $folderName = Split-Path -Path $resolvedTargetFolder -Leaf

        # Search for candidates in the staging directory
        $selectedCandidate = $null
        if (Test-Path -LiteralPath $stagingRoot) {
            try {
                $candidates = Get-ChildItem -LiteralPath $stagingRoot -Directory -ErrorAction Stop | Where-Object {
                    ($_.Name -eq $folderName -or $_.Name -match "^$([regex]::Escape($folderName))_\d{14}$")
                }
                foreach ($candidate in $candidates) {
                    if (Test-Path -LiteralPath $candidate.FullName) {
                        $selectedCandidate = $candidate
                        break
                    }
                }
            } catch {
                Throw "Failed to scan staging directory '$stagingRoot': $_"
            }
        }

        if ($null -eq $selectedCandidate) {
            Write-Error "No matching staged folder found in '$stagingRoot' for folder '$folderName'."
            continue
        }

        # Perform rollback with ShouldProcess support
        if ($PSCmdlet.ShouldProcess($resolvedTargetFolder, "Restore directory from '$($selectedCandidate.FullName)'")) {
            $parentDir = Split-Path -Path $resolvedTargetFolder -Parent
            if (-not (Test-Path -LiteralPath $parentDir)) {
                Write-Verbose "Creating parent directory: $parentDir"
                try {
                    $null = New-Item -ItemType Directory -Path $parentDir -Force -ErrorAction Stop
                } catch {
                    Throw "Failed to create parent directory '$parentDir': $_"
                }
            }

            try {
                Write-Verbose "Restoring '$($selectedCandidate.FullName)' to '$resolvedTargetFolder'"
                Move-Item -LiteralPath $selectedCandidate.FullName -Destination $resolvedTargetFolder -Force -ErrorAction Stop
            } catch {
                Throw "Failed to restore folder '$($selectedCandidate.FullName)' to '$resolvedTargetFolder': $_"
            }
        }
    }
}
