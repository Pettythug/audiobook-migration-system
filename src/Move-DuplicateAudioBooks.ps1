$csvPath = "C:\Users\wance\.gemini\antigravity\Organize Audio Books\gdrive_manifest.csv"
$pcloudDir = "C:\Users\wance\.gemini\antigravity\Organize Audio Books\AudioBook_Migration_Project\tests\Mock_G_Drive\My Drive\pcloud"
$toDeleteDir = Join-Path -Path $pcloudDir -ChildPath "To Delete Audio Books"

$manifest = Import-Csv -Path $csvPath
$csvFolders = $manifest | Select-Object -ExpandProperty highest_common_parent

$folders = Get-ChildItem -Path $pcloudDir -Directory

foreach ($folder in $folders) {
    if ($folder.Name -eq "To Delete Audio Books") {
        continue
    }

    if ($csvFolders -contains $folder.Name) {
        try {
            Move-Item -Path $folder.FullName -Destination $toDeleteDir -ErrorAction Stop
            Write-Output "Successfully moved $($folder.Name) to To Delete Audio Books."
        } catch {
            Write-Error "Failed to move $($folder.Name): $_"
        }
    }
}
