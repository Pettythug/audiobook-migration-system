[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true)]
    [string]$TargetDirectory,

    [Parameter(Mandatory=$true)]
    [string]$HoldingCellDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $HoldingCellDirectory)) {
    if ($PSCmdlet.ShouldProcess($HoldingCellDirectory, "Create Holding Cell Directory")) {
        New-Item -Path $HoldingCellDirectory -ItemType Directory -Force | Out-Null
    }
}

try {
    # Recursively get all directories
    $AllDirs = Get-ChildItem -LiteralPath $TargetDirectory -Directory -Recurse

    # Sort descending by path length to process bottom-up
    $AllDirs = $AllDirs | Sort-Object -Property @{Expression={$_.FullName.Length}; Descending=$true}

    foreach ($Dir in $AllDirs) {
        # Don't process if the directory somehow became the holding cell itself or is inside it
        if ($Dir.FullName.StartsWith($HoldingCellDirectory, [StringComparison]::InvariantCultureIgnoreCase)) {
            continue
        }

        # Check if directory exists (in case it was moved as part of a parent folder move)
        if (-not (Test-Path -LiteralPath $Dir.FullName)) {
            continue
        }

        # Check if directory is completely empty
        $Items = @(Get-ChildItem -LiteralPath $Dir.FullName -Force)
        if ($Items.Count -eq 0) {
            $Dest = Join-Path -Path $HoldingCellDirectory -ChildPath $Dir.Name
            
            # Conflict resolution: if destination exists, append a GUID
            if (Test-Path -LiteralPath $Dest) {
                $Guid = [guid]::NewGuid().ToString().Substring(0,8)
                $Dest = "${Dest}_${Guid}"
            }

            if ($PSCmdlet.ShouldProcess($Dir.FullName, "Move empty directory to $Dest")) {
                try {
                    Move-Item -LiteralPath $Dir.FullName -Destination $Dest -Force
                } catch {
                    Write-Error "Failed to move directory $($Dir.FullName): $_"
                }
            }
        }
    }
} catch {
    Write-Error "Failed to process TargetDirectory: $_"
}
