param(
    [Parameter(Mandatory=$true)]
    [string]$MasterDirectory,

    [Parameter(Mandatory=$true)]
    [string[]]$TargetDirectories
)

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

# Scan Master
try {
    $MasterBooks = Get-ChildItem -LiteralPath $MasterDirectory -Directory
    foreach ($Book in $MasterBooks) {
        $CleanTitle = Get-CleanTitle -FolderName $Book.Name
        $MasterHashtable[$CleanTitle] = $Book.FullName
    }
} catch {
    Write-Error "Failed to scan MasterDirectory: $_"
    return
}

# Scan Targets
foreach ($TargetRoot in $TargetDirectories) {
    try {
        $TargetBooks = Get-ChildItem -LiteralPath $TargetRoot -Directory
        $ToDeleteDir = Join-Path -Path $TargetRoot -ChildPath "To Delete Audio Books"
        
        if (-not (Test-Path -LiteralPath $ToDeleteDir)) {
            New-Item -Path $ToDeleteDir -ItemType Directory -Force | Out-Null
        }

        foreach ($Book in $TargetBooks) {
            if ($Book.Name -eq "To Delete Audio Books") { continue }
            
            # Check Empty Shell
            $AudioFiles = Get-ChildItem -LiteralPath $Book.FullName -Recurse -File | Where-Object { $_.Extension -match '(?i)\.(mp3|m4b|m4a|flac)$' }
            if (@($AudioFiles).Count -eq 0) {
                # Empty Shell
                try {
                    $Dest = Join-Path -Path $ToDeleteDir -ChildPath $Book.Name
                    Move-Item -LiteralPath $Book.FullName -Destination $Dest -Force
                    "$($Book.FullName),Reason: Empty Shell" | Out-File -LiteralPath $LogFile -Append -Encoding utf8
                } catch {
                    Write-Error "Failed to move empty shell $($Book.FullName): $_"
                }
                continue
            }

            # Asymmetrical Resolution Engine
            $CleanTitle = Get-CleanTitle -FolderName $Book.Name
            if ($MasterHashtable.ContainsKey($CleanTitle)) {
                $MasterBookPath = $MasterHashtable[$CleanTitle]
                $MasterSize = Get-FolderSize -FolderPath $MasterBookPath
                $TargetSize = Get-FolderSize -FolderPath $Book.FullName

                if ($MasterSize -ge $TargetSize) {
                    # Master >= Target
                    try {
                        $Dest = Join-Path -Path $ToDeleteDir -ChildPath $Book.Name
                        Move-Item -LiteralPath $Book.FullName -Destination $Dest -Force
                        "$($Book.FullName),Reason: Exact/Inferior Duplicate" | Out-File -LiteralPath $LogFile -Append -Encoding utf8
                    } catch {
                        Write-Error "Failed to move inferior duplicate $($Book.FullName): $_"
                    }
                } else {
                    # Master < Target
                    "$($Book.FullName),Reason: Target Superior" | Out-File -LiteralPath $LogFile -Append -Encoding utf8
                }
            }
        }
    } catch {
        Write-Error "Failed to process TargetDirectory $($TargetRoot): $_"
    }
}
