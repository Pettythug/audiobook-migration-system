<#
.SYNOPSIS
    Pre-Stage Non-Media Residuals into 02_Projects and 03_Personal

.DESCRIPTION
    Relocates non-media development directories (PyCharm, Rackspace) and workout directories
    (Workout Stuff) from G:\My Drive\04_Media\Drive G\To Delete Empty Folders into G:\My Drive\02_Projects
    and G:\My Drive\03_Personal.
    
    Safeguards:
    - Long-path \\?\ handling
    - Retry-with-backoff for Google Drive locks
    - Zero deletions (no Remove-Item)
    - Zero interaction with P:\ drive
    - Comprehensive CSV audit logging
#>
[CmdletBinding(SupportsShouldProcess)]
Param(
    [Parameter(Mandatory=$false)]
    [string]$SourceBase = "G:\My Drive\04_Media\Drive G\To Delete Empty Folders",

    [Parameter(Mandatory=$false)]
    [string]$ProjectsTarget = "G:\My Drive\02_Projects",

    [Parameter(Mandatory=$false)]
    [string]$PersonalTarget = "G:\My Drive\03_Personal",

    [Parameter(Mandatory=$false)]
    [string]$RepoLogPath = "C:\Users\wance\Documents\Git\audiobook-migration-system\Manual_Review_Log.csv",

    [Parameter(Mandatory=$false)]
    [string]$MediaLogPath = "G:\My Drive\04_Media\Manual_Review_Log.csv"
)

$ErrorActionPreference = "Stop"

# Boundary Assertion: P:\ drive is strictly prohibited
if ($SourceBase -like "P:\*" -or $ProjectsTarget -like "P:\*" -or $PersonalTarget -like "P:\*") {
    throw "Security Boundary Violation: Access to P:\ drive is strictly prohibited."
}

function Move-DirectoryWithRetry {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath
    )

    $maxRetries = 3
    $retryIntervals = @(2, 4, 8)

    $destParent = [System.IO.Path]::GetDirectoryName($DestinationPath)
    if (-not [System.IO.Directory]::Exists("\\?\$destParent")) {
        if ($PSCmdlet.ShouldProcess($destParent, "Create Directory")) {
            [System.IO.Directory]::CreateDirectory("\\?\$destParent") | Out-Null
            Write-Host "Created target parent directory: $destParent" -ForegroundColor Green
        }
    }

    $attempt = 0
    while ($attempt -le $maxRetries) {
        try {
            if ($PSCmdlet.ShouldProcess($SourcePath, "Move to $DestinationPath")) {
                [System.IO.Directory]::Move("\\?\$SourcePath", "\\?\$DestinationPath")
                Write-Host "Successfully moved: $SourcePath -> $DestinationPath" -ForegroundColor Green
            }
            return $true
        }
        catch {
            if ($attempt -eq $maxRetries) {
                Write-Error "Failed to move '$SourcePath' after $($maxRetries) retries: $_"
                throw
            }
            Write-Warning "Lock or conflict encountered on '$SourcePath'. Retrying in $($retryIntervals[$attempt]) seconds..."
            Start-Sleep -Seconds $retryIntervals[$attempt]
            $attempt++
        }
    }
}

function Log-Relocation {
    param(
        [string]$Action,
        [string]$Source,
        [string]$Destination,
        [string]$Reason
    )

    $date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $csvLineDetailed = "`"$date`",`"$Action`",`"$Source`",`"$Destination`",`"$Reason`""
    $csvLineSimple = "$Source,Reason: $Reason"

    if ($PSCmdlet.ShouldProcess("Manual_Review_Log.csv", "Append log: $Action - $Reason")) {
        # Append to Media Log (Detailed schema)
        if (-not [string]::IsNullOrWhiteSpace($MediaLogPath)) {
            if (-not [System.IO.File]::Exists("\\?\$MediaLogPath")) {
                "Timestamp,Action,Source,Destination,Reason" | Out-File -LiteralPath "\\?\$MediaLogPath" -Encoding UTF8
            }
            $csvLineDetailed | Out-File -LiteralPath "\\?\$MediaLogPath" -Encoding UTF8 -Append
        }

        # Append to Repo Log (Simple schema)
        if (-not [string]::IsNullOrWhiteSpace($RepoLogPath) -and [System.IO.File]::Exists("\\?\$RepoLogPath")) {
            $csvLineSimple | Out-File -LiteralPath "\\?\$RepoLogPath" -Encoding UTF8 -Append
        }
    }
}

$moves = @(
    @{
        Name = "PyCharm"
        Source = Join-Path $SourceBase "PyCharm"
        Destination = Join-Path $ProjectsTarget "PyCharm"
        Reason = "Non-media development asset relocated from 04_Media to 02_Projects"
    },
    @{
        Name = "Rackspace"
        Source = Join-Path $SourceBase "Rackspace"
        Destination = Join-Path $ProjectsTarget "Rackspace"
        Reason = "Non-media development asset relocated from 04_Media to 02_Projects"
    },
    @{
        Name = "Workout Stuff"
        Source = Join-Path $SourceBase "Workout Stuff"
        Destination = Join-Path $PersonalTarget "Workout Stuff"
        Reason = "Non-media personal asset relocated from 04_Media to 03_Personal"
    }
)

Write-Host "=== Starting TASK-011 Non-Media Pre-Staging Execution ===" -ForegroundColor Cyan
$executedMoves = 0

foreach ($m in $moves) {
    $src = $m.Source
    $dest = $m.Destination
    $name = $m.Name
    $reason = $m.Reason

    if (-not [System.IO.Directory]::Exists("\\?\$src")) {
        Write-Warning "Source directory not found: $src. Skipping."
        continue
    }

    if ([System.IO.Directory]::Exists("\\?\$dest")) {
        Write-Warning "Destination directory already exists: $dest. Halting to avoid overwriting."
        continue
    }

    Move-DirectoryWithRetry -SourcePath $src -DestinationPath $dest
    Log-Relocation -Action "PRESTAGE_NON_MEDIA" -Source $src -Destination $dest -Reason $reason
    $executedMoves++
}

Write-Host "=== Execution Complete. Total Directories Relocated: $executedMoves ===" -ForegroundColor Cyan
