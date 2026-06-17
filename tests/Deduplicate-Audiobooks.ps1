param (
    [Parameter(Mandatory=$false)]
    [string]$TargetDirectory = ".\",
    [Parameter(Mandatory=$false)]
    [string]$LogFile = ".\Manual_Review_Log.csv"
)

$ErrorActionPreference = "Stop"

$audioExtensions = @('.mp3', '.m4a', '.m4b', '.flac', '.wav', '.wma', '.ogg')

Try {
    $targetRoot = (Resolve-Path -LiteralPath $TargetDirectory).Path
    $deleteDir = Join-Path -Path $targetRoot -ChildPath "To Delete Audio Books"
    if (-not (Test-Path -LiteralPath $deleteDir)) {
        New-Item -ItemType Directory -Path $deleteDir -Force | Out-Null
    }

    # 1. Dynamic Anchor: Scan for all audio files infinitely deep
    $audioFiles = Get-ChildItem -LiteralPath $targetRoot -Recurse -File | Where-Object { $audioExtensions -contains $_.Extension.ToLower() }
    
    $bookFolders = @{}

    foreach ($file in $audioFiles) {
        # Ensure we don't process files already in the delete dir
        if ($file.FullName.StartsWith($deleteDir)) { continue }

        $curr = $file.Directory
        $isBookFolder = $false

        # Step up looking for [ID]
        while ($curr -and $curr.FullName -ne $targetRoot) {
            if ($curr.Name -match '\[.*?\]') {
                if (-not $bookFolders.ContainsKey($curr.FullName)) {
                    $bookFolders[$curr.FullName] = $curr
                }
                $isBookFolder = $true
                break
            }
            $curr = $curr.Parent
        }
        
        # Step up above CD*/Part* if no [ID] found
        if (-not $isBookFolder) {
            $curr = $file.Directory
            while ($curr -and $curr.FullName -ne $targetRoot) {
                if ($curr.Name -match '^(CD|Part)\s*\d*$' -and $curr.Parent) {
                    $curr = $curr.Parent
                } else {
                    if (-not $bookFolders.ContainsKey($curr.FullName)) {
                        $bookFolders[$curr.FullName] = $curr
                    }
                    break
                }
            }
        }
    }

    # Establish Clean Titles
    $cleanTitles = @{}
    foreach ($folder in $bookFolders.Values) {
        $cleanTitle = ($folder.Name -replace '\s*\[.*?\]\s*', '').Trim()
        $cleanTitles[$cleanTitle] = $true
    }
    
    # Find Empty Shells by scanning all directories for matching clean titles
    $allDirs = Get-ChildItem -LiteralPath $targetRoot -Directory -Recurse
    foreach ($dir in $allDirs) {
        if ($dir.FullName.StartsWith($deleteDir)) { continue }

        $cleanTitle = ($dir.Name -replace '\s*\[.*?\]\s*', '').Trim()
        if ($cleanTitles.ContainsKey($cleanTitle) -and -not $bookFolders.ContainsKey($dir.FullName)) {
            # Make sure it's not a child of an existing book folder
            $parentIsBookFolder = $false
            $p = $dir.Parent
            while ($p -and $p.FullName -ne $targetRoot) {
                if ($bookFolders.ContainsKey($p.FullName)) {
                    $parentIsBookFolder = $true
                    break
                }
                $p = $p.Parent
            }
            if (-not $parentIsBookFolder) {
                $bookFolders[$dir.FullName] = $dir
            }
        }
    }

    # Group Folders
    $groupedFolders = @{}
    foreach ($folder in $bookFolders.Values) {
        $cleanTitle = ($folder.Name -replace '\s*\[.*?\]\s*', '').Trim()
        if (-not $groupedFolders.ContainsKey($cleanTitle)) {
            $groupedFolders[$cleanTitle] = @()
        }
        $groupedFolders[$cleanTitle] += $folder
    }

    # Process Groups
    foreach ($group in $groupedFolders.GetEnumerator()) {
        $title = $group.Key
        $folders = $group.Value
        
        if ($folders.Count -lt 2) {
            continue
        }
        
        $stats = @()
        foreach ($folder in $folders) {
            if (-not (Test-Path -LiteralPath $folder.FullName)) { continue }
            
            $allSubFiles = Get-ChildItem -LiteralPath $folder.FullName -Recurse -File -Force
            $totalCount = @($allSubFiles).Count
            $totalSize = 0
            $audioCount = 0
            foreach ($f in $allSubFiles) {
                $totalSize += $f.Length
                if ($audioExtensions -contains $f.Extension.ToLower()) {
                    $audioCount++
                }
            }
            
            $stats += [PSCustomObject]@{
                Folder = $folder
                TotalFiles = $totalCount
                TotalSizeMB = if ($totalCount -eq 0) { 0 } else { [math]::Round($totalSize / 1MB, 2) }
                AudioCount = $audioCount
            }
        }
        
        if ($stats.Count -lt 2) { continue }
        
        # Sort by AudioCount DESC, Size DESC
        $sortedStats = $stats | Sort-Object AudioCount, TotalSizeMB -Descending
        $keeper = $sortedStats[0]
        $candidates = $sortedStats | Select-Object -Skip 1
        
        foreach ($candidate in $candidates) {
            $destPath = Join-Path -Path $deleteDir -ChildPath $candidate.Folder.Name
            if (Test-Path -LiteralPath $destPath) {
                $destPath = Join-Path -Path $deleteDir -ChildPath ($candidate.Folder.Name + "_" + [guid]::NewGuid().ToString().Substring(0,8))
            }

            if ($candidate.TotalFiles -eq $keeper.TotalFiles -and $candidate.TotalSizeMB -eq $keeper.TotalSizeMB) {
                # Apples-to-Apples
                Try {
                    Move-Item -LiteralPath $candidate.Folder.FullName -Destination $destPath -Force
                } Catch {
                    Write-Warning "Failed to move $($candidate.Folder.FullName): $_"
                }
            }
            elseif ($keeper.AudioCount -gt 0 -and $candidate.AudioCount -eq 0) {
                # Empty Shell
                Try {
                    Move-Item -LiteralPath $candidate.Folder.FullName -Destination $destPath -Force
                } Catch {
                    Write-Warning "Failed to move $($candidate.Folder.FullName): $_"
                }
            }
            elseif ($keeper.AudioCount -gt 0 -and $candidate.AudioCount -gt 0) {
                # Asymmetrical
                Try {
                    Move-Item -LiteralPath $candidate.Folder.FullName -Destination $destPath -Force
                    
                    $logObj = [PSCustomObject]@{
                        CleanTitle = $title
                        KeeperFolder = $keeper.Folder.Name
                        KeeperAudioCount = $keeper.AudioCount
                        KeeperTotalFiles = $keeper.TotalFiles
                        KeeperSizeMB = $keeper.TotalSizeMB
                        CandidateFolder = $candidate.Folder.Name
                        CandidateAudioCount = $candidate.AudioCount
                        CandidateTotalFiles = $candidate.TotalFiles
                        CandidateSizeMB = $candidate.TotalSizeMB
                    }
                    $logObj | Export-Csv -LiteralPath $LogFile -Append -NoTypeInformation -Force
                } Catch {
                    Write-Warning "Failed to move and log $($candidate.Folder.FullName): $_"
                }
            }
        }
    }
}
Catch {
    Write-Error $_
}
