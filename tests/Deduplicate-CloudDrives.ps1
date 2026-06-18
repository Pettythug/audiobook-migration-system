param (
    [Parameter(Mandatory=$true)]
    [string]$MasterDirectory,

    [Parameter(Mandatory=$true)]
    [string[]]$TargetDirectories
)

try {
    # 1. Master Scan: Build a hash table of "Clean Titles" existing in the Master directory (stripping [ID] tags).
    $masterTitles = @{}
    
    if (Test-Path -LiteralPath $MasterDirectory) {
        $masterFolders = Get-ChildItem -LiteralPath $MasterDirectory -Directory
        foreach ($folder in $masterFolders) {
            $cleanTitle = $folder.Name -replace '\[.*?\]', ''
            $cleanTitle = $cleanTitle.Trim()
            if (![string]::IsNullOrWhiteSpace($cleanTitle)) {
                $masterTitles[$cleanTitle] = $true
            }
        }
    } else {
        Write-Error "Master directory not found: $MasterDirectory"
        return
    }

    # 3. Duplicate Routing: Loop through the target directories array.
    foreach ($targetDir in $TargetDirectories) {
        if (-not (Test-Path -LiteralPath $targetDir)) {
            Write-Warning "Target directory not found: $targetDir"
            continue
        }

        # 4. Execution Engine: "To Delete Audio Books" staging folder located dynamically within the root of that specific target directory.
        $toDeleteDir = Join-Path $targetDir "To Delete Audio Books"
        
        $targetFolders = Get-ChildItem -LiteralPath $targetDir -Directory | Where-Object { $_.Name -ne "To Delete Audio Books" }
        foreach ($folder in $targetFolders) {
            $cleanTitle = $folder.Name -replace '\[.*?\]', ''
            $cleanTitle = $cleanTitle.Trim()

            if (![string]::IsNullOrWhiteSpace($cleanTitle) -and $masterTitles.ContainsKey($cleanTitle)) {
                # Duplicate found, move it to the To Delete folder
                if (-not (Test-Path -LiteralPath $toDeleteDir)) {
                    New-Item -ItemType Directory -Path $toDeleteDir -Force | Out-Null
                }

                $destination = Join-Path $toDeleteDir $folder.Name
                try {
                    Move-Item -LiteralPath $folder.FullName -Destination $toDeleteDir -Force
                    Write-Host "Moved duplicate: $($folder.FullName) -> $destination"
                } catch {
                    Write-Error "Failed to move duplicate folder $($folder.FullName): $_"
                }
            }
        }
    }
} catch {
    Write-Error "An unexpected error occurred: $_"
}
