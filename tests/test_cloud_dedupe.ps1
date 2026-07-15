$testRoot = Join-Path $env:TEMP "AudiobookDedupeTest_$(Get-Random)"
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

try {
    # Create Mock Master directory
    $masterDir = Join-Path $testRoot "Master"
    New-Item -ItemType Directory -Path $masterDir | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $masterDir "Book A [ID123]") | Out-Null
    New-Item -ItemType File -Path (Join-Path $masterDir "Book A [ID123]\audio.mp3") -Value "AUDIO" | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $masterDir "Book B [ID456]") | Out-Null
    New-Item -ItemType File -Path (Join-Path $masterDir "Book B [ID456]\audio.mp3") -Value "AUDIO" | Out-Null

    # Create Mock Target directories
    $targets = @()
    for ($i = 1; $i -le 4; $i++) {
        $targetDir = Join-Path $testRoot "Target$i"
        $targets += $targetDir
        New-Item -ItemType Directory -Path $targetDir | Out-Null
        
        # Add a duplicate that matches master
        New-Item -ItemType Directory -Path (Join-Path $targetDir "Book A [ID99$i]") | Out-Null
        New-Item -ItemType File -Path (Join-Path $targetDir "Book A [ID99$i]\audio.mp3") -Value "AUDIO" | Out-Null
        # Add a unique book
        New-Item -ItemType Directory -Path (Join-Path $targetDir "Unique Book $i [ID00$i]") | Out-Null
        New-Item -ItemType File -Path (Join-Path $targetDir "Unique Book $i [ID00$i]\audio.mp3") -Value "AUDIO" | Out-Null
        
        # In one target, let's also put Book B duplicate
        if ($i -eq 2) {
            New-Item -ItemType Directory -Path (Join-Path $targetDir "Book B [ID88$i]") | Out-Null
            New-Item -ItemType File -Path (Join-Path $targetDir "Book B [ID88$i]\audio.mp3") -Value "AUDIO" | Out-Null
        }
    }

    # Run the script
    $scriptPath = Join-Path $PSScriptRoot "../src/Deduplicate-CloudDrives.ps1"
    & $scriptPath -MasterDirectory $masterDir -TargetDirectories $targets

    # Verify
    $allPassed = $true
    for ($i = 1; $i -le 4; $i++) {
        $targetDir = $targets[$i-1]
        $toDeleteDir = Join-Path $targetDir "To Delete Audio Books"
        
        # Check if To Delete Audio Books exists
        if (-not (Test-Path -LiteralPath $toDeleteDir)) {
            Write-Error "Target$i 'To Delete Audio Books' folder was not created."
            $allPassed = $false
        }

        # Check if duplicates were moved
        $movedBookA = Join-Path $toDeleteDir "Book A [ID99$i]"
        if (-not (Test-Path -LiteralPath $movedBookA)) {
            Write-Error "Target$i did not move Book A correctly."
            $allPassed = $false
        }

        # Check if unique books were NOT moved
        $uniqueBook = Join-Path $targetDir "Unique Book $i [ID00$i]"
        if (-not (Test-Path -LiteralPath $uniqueBook)) {
            Write-Error "Target$i incorrectly moved the unique book."
            $allPassed = $false
        }
        
        if ($i -eq 2) {
            $movedBookB = Join-Path $toDeleteDir "Book B [ID88$i]"
            if (-not (Test-Path -LiteralPath $movedBookB)) {
                Write-Error "Target$i did not move Book B correctly."
                $allPassed = $false
            }
        }
    }

    if ($allPassed) {
        Write-Host "All mock tests passed 100%!" -ForegroundColor Green
    } else {
        Write-Error "Tests failed."
    }
} finally {
    Write-Host "Test completed."
}
