$ErrorActionPreference = 'Stop'

Describe "Compare-ManifestToPcloud.ps1" {
    BeforeAll {
        $scriptPath = "$PSScriptRoot\Compare-ManifestToPcloud.ps1"
        $tempDir = New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot "TempTestDir") -Force
        
        # Create mock target directory
        $targetDir = New-Item -ItemType Directory -Path (Join-Path $tempDir "Target") -Force
        New-Item -ItemType Directory -Path (Join-Path $targetDir "Book A [ID123]") | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $targetDir "Book B [ID456]") | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $targetDir "Book C [ID789]") | Out-Null
        
        # Create mock manifests
        $pcloudCsv = Join-Path $tempDir "pcloud.csv"
        $gdriveCsv = Join-Path $tempDir "gdrive.csv"
        
        @"
highest_common_parent,file_count,total_size_bytes,migration_decision
Book A [ID123],10,100,Migrate
"@ | Out-File -FilePath $pcloudCsv -Encoding UTF8

        @"
highest_common_parent,file_count,total_size_bytes,migration_decision
renamed\Not On Phone\Author\Book B,20,200,Migrate
Book D,5,50,Migrate
"@ | Out-File -FilePath $gdriveCsv -Encoding UTF8

        $reportPath = Join-Path $tempDir "report.csv"
        
        & $scriptPath -TargetDirectory $targetDir.FullName -PCloudManifestPath $pcloudCsv -GDriveManifestPath $gdriveCsv -ReportOutputPath $reportPath
    }

    It "Should create a migration report" {
        $reportPath = Join-Path $PSScriptRoot "TempTestDir\report.csv"
        Test-Path $reportPath | Should Be $true
    }

    It "Should categorize synced and pending books correctly" {
        $reportPath = Join-Path $PSScriptRoot "TempTestDir\report.csv"
        $report = Import-Csv $reportPath
        
        $report.Count | Should Be 3
        
        $bookA = $report | Where-Object { $_.LocalFolder -eq "Book A [ID123]" }
        $bookA.CleanTitle | Should Be "Book A"
        $bookA.Status | Should Be "[SYNCED]"
        
        $bookB = $report | Where-Object { $_.LocalFolder -eq "Book B [ID456]" }
        $bookB.CleanTitle | Should Be "Book B"
        $bookB.Status | Should Be "[SYNCED]"
        
        $bookC = $report | Where-Object { $_.LocalFolder -eq "Book C [ID789]" }
        $bookC.CleanTitle | Should Be "Book C"
        $bookC.Status | Should Be "[PENDING UPLOAD]"
    }

    AfterAll {
        $tempDir = Join-Path $PSScriptRoot "TempTestDir"
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
        }
    }
}
