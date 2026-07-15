[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true)]
    [string[]]$SourceDirectories,

    [Parameter(Mandatory=$true)]
    [string]$DestinationDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# LogFile path (local to repository)
$LogFile = "Manual_Review_Log.csv"
if (-not (Test-Path -LiteralPath $LogFile)) {
    try {
        "TargetFolder,Reason" | Out-File -LiteralPath $LogFile -Encoding utf8
    } catch {
        Write-Warning "Unable to initialize log file ${LogFile}: $_"
    }
}

# Ensure destination directory exists or creates it under ShouldProcess
if (-not (Test-Path -LiteralPath $DestinationDirectory)) {
    if ($PSCmdlet.ShouldProcess($DestinationDirectory, "Create Destination Directory")) {
        try {
            New-Item -Path $DestinationDirectory -ItemType Directory -Force | Out-Null
            Write-Output "Created destination directory: $DestinationDirectory"
        } catch {
            Write-Error "Failed to create destination directory '$DestinationDirectory': $_"
            return
        }
    }
}

# Sweep each source directory for remaining audiobook folders (directories)
foreach ($SourceRoot in $SourceDirectories) {
    if (-not (Test-Path -LiteralPath $SourceRoot)) {
        Write-Warning "Source directory does not exist: $SourceRoot"
        continue
    }

    Write-Verbose "Scanning source directory: $SourceRoot"

    try {
        # Fetch only the top-level directories in the source root
        $SubDirectories = Get-ChildItem -LiteralPath $SourceRoot -Directory
    } catch {
        Write-Error "Failed to list directories under '$SourceRoot': $_"
        continue
    }

    foreach ($Dir in $SubDirectories) {
        $DirName = $Dir.Name

        # Exclude specific metadata, system, or delete folders
        if ($DirName -eq "To Delete Audio Books" -or 
            $DirName -eq "To Delete Empty Folders" -or 
            $DirName -eq ".git" -or 
            $DirName -eq ".agents") {
            continue
        }

        # Determine target path
        $DestPath = Join-Path -Path $DestinationDirectory -ChildPath $DirName

        # Handle name collisions: append timestamp to ensure unique target
        if (Test-Path -LiteralPath $DestPath) {
            $Timestamp = (Get-Date -Format "yyyyMMddHHmmss")
            $DestPath = "${DestPath}_${Timestamp}"
            Write-Warning "Collision detected for '$DirName'. Appending timestamp: '$DestPath'"
        }

        # Perform the direct, same-volume Move-Item
        if ($PSCmdlet.ShouldProcess($Dir.FullName, "Move to $DestPath")) {
            try {
                Move-Item -LiteralPath $Dir.FullName -Destination $DestPath -Force
                Write-Output "Successfully moved: $($Dir.FullName) -> $DestPath"
                
                # Append to the log if successfully moved
                if (Test-Path -LiteralPath $LogFile) {
                    "$($Dir.FullName),Reason: Consolidated to Organized Audiobooks" | Out-File -LiteralPath $LogFile -Append -Encoding utf8
                }
            } catch {
                Write-Error "Failed to move '$($Dir.FullName)' to '$DestPath': $_"
            }
        }
    }
}
