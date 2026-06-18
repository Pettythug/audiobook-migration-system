param(
    [Parameter(Mandatory=$true)]
    [string]$MasterDirectory,

    [Parameter(Mandatory=$true)]
    [string[]]$TargetDirectories
)

$ErrorActionPreference = "Stop"

$LogFile = "Manual_Review_Log.csv"
if (-not (Test-Path -LiteralPath $LogFile)) {
    "TargetFolder,Reason" | Out-File -LiteralPath $LogFile -Encoding utf8
}

function Get-CleanTitle {
    param([string]$FolderName)
    return ($FolderName -replace '\[.*?\]', '') -replace '^\s+|\s+$', '' -replace '\s+', ' '
}

function Get-FolderSize {
    param([string]$FolderPath)
    $size = 0
    Get-ChildItem -LiteralPath $FolderPath -Recurse -File | ForEach-Object {
        $size += $_.Length
    }
    return $size
}

$MasterHashtable = @{}

# Scan Master for Anchored Folders (Leaf folders physically containing audio files)
try {
    $AllMasterDirs = @(Get-ChildItem -LiteralPath $MasterDirectory -Recurse -Directory)
    foreach ($Dir in $AllMasterDirs) {
        $AudioFiles = @(Get-ChildItem -LiteralPath $Dir.FullName -File | Where-Object { $_.Extension -match '(?i)\.(mp3|m4b|m4a|flac)$' })
        if ($AudioFiles.Count -gt 0) {
            $CleanTitle = Get-CleanTitle -FolderName $Dir.Name
            $MasterHashtable[$CleanTitle] = $Dir.FullName
        }
    }
} catch {
    Write-Error "Failed to scan MasterDirectory: $_"
    return
}

# Scan Targets
foreach ($TargetRoot in $TargetDirectories) {
    try {
        $AllTargetDirs = @(Get-ChildItem -LiteralPath $TargetRoot -Recurse -Directory)
        $ToDeleteDir = Join-Path -Path $TargetRoot -ChildPath "To Delete Audio Books"
        
        if (-not (Test-Path -LiteralPath $ToDeleteDir)) {
            New-Item -Path $ToDeleteDir -ItemType Directory -Force | Out-Null
        }

        $AnchoredFolders = @()
        $EmptyShells = @()

        foreach ($Dir in $AllTargetDirs) {
            if ($Dir.FullName -match [regex]::Escape($ToDeleteDir)) { continue }
            if ($Dir.Name -eq "To Delete Audio Books") { continue }
            
            $AudioFiles = @(Get-ChildItem -LiteralPath $Dir.FullName -File | Where-Object { $_.Extension -match '(?i)\.(mp3|m4b|m4a|flac)$' })
            if ($AudioFiles.Count -gt 0) {
                $AnchoredFolders += $Dir
            } else {
                $RecAudio = @(Get-ChildItem -LiteralPath $Dir.FullName -Recurse -File | Where-Object { $_.Extension -match '(?i)\.(mp3|m4b|m4a|flac)$' })
                if ($RecAudio.Count -eq 0) {
                    $EmptyShells += $Dir
                }
            }
        }

        # Process Empty Shells
        # Sort ascending by depth so we move parents before children, which is fine since moving a parent moves everything
        $EmptyShells = $EmptyShells | Sort-Object @{Expression={$_.FullName.Length}; Ascending=$true}
        foreach ($Shell in $EmptyShells) {
            if (-not (Test-Path -LiteralPath $Shell.FullName)) { continue }
            try {
                $Dest = Join-Path -Path $ToDeleteDir -ChildPath $Shell.Name
                if (Test-Path -LiteralPath $Dest) {
                    $Dest = $Dest + "_" + (Get-Date -Format "yyyyMMddHHmmss")
                }
                Move-Item -LiteralPath $Shell.FullName -Destination $Dest -Force
                "$($Shell.FullName),Reason: Empty Shell" | Out-File -LiteralPath $LogFile -Append -Encoding utf8
            } catch {
                Write-Error "Failed to move empty shell $($Shell.FullName): $_"
            }
        }

        # Process Anchored Target Folders
        foreach ($Anchored in $AnchoredFolders) {
            if (-not (Test-Path -LiteralPath $Anchored.FullName)) { continue }
            $CleanTitle = Get-CleanTitle -FolderName $Anchored.Name
            if ($MasterHashtable.ContainsKey($CleanTitle)) {
                $MasterBookPath = $MasterHashtable[$CleanTitle]
                $MasterSize = Get-FolderSize -FolderPath $MasterBookPath
                $TargetSize = Get-FolderSize -FolderPath $Anchored.FullName

                if ($MasterSize -ge $TargetSize) {
                    try {
                        $Dest = Join-Path -Path $ToDeleteDir -ChildPath $Anchored.Name
                        if (Test-Path -LiteralPath $Dest) {
                            $Dest = $Dest + "_" + (Get-Date -Format "yyyyMMddHHmmss")
                        }
                        Move-Item -LiteralPath $Anchored.FullName -Destination $Dest -Force
                        "$($Anchored.FullName),Reason: Exact/Inferior Duplicate" | Out-File -LiteralPath $LogFile -Append -Encoding utf8
                    } catch {
                        Write-Error "Failed to move inferior duplicate $($Anchored.FullName): $_"
                    }
                } else {
                    "$($Anchored.FullName),Reason: Target Superior" | Out-File -LiteralPath $LogFile -Append -Encoding utf8
                }
            }
        }
    } catch {
        Write-Error "Failed to process TargetDirectory $($TargetRoot): $_"
    }
}
