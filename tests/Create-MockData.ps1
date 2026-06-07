$testsDir = "c:\Users\wance\.gemini\antigravity\Organize Audio Books\AudioBook_Migration_Project\tests"
$mockGDrive = Join-Path $testsDir "Mock_G_Drive\My Drive"
$audioBooksDir = Join-Path $mockGDrive "Audio Books"
$pcloudDir = Join-Path $mockGDrive "pcloud"
$toDeleteDir = Join-Path $pcloudDir "To Delete Audio Books"

try {
    Write-Output "Starting mock data creation..."

    Write-Output "Creating base directories..."
    New-Item -ItemType Directory -Force -Path $audioBooksDir | Out-Null
    New-Item -ItemType Directory -Force -Path $toDeleteDir | Out-Null

    Write-Output "Creating books in Audio Books..."
    New-Item -ItemType Directory -Force -Path (Join-Path $audioBooksDir "Beastborne") | Out-Null
    New-Item -ItemType File -Force -Path (Join-Path $audioBooksDir "Beastborne\01.mp3") | Out-Null
    
    New-Item -ItemType Directory -Force -Path (Join-Path $audioBooksDir "Legend of Drizzt") | Out-Null
    New-Item -ItemType File -Force -Path (Join-Path $audioBooksDir "Legend of Drizzt\01.mp3") | Out-Null
    
    New-Item -ItemType Directory -Force -Path (Join-Path $audioBooksDir "Harry Potter") | Out-Null
    New-Item -ItemType File -Force -Path (Join-Path $audioBooksDir "Harry Potter\01.mp3") | Out-Null

    Write-Output "Creating books in pcloud..."
    New-Item -ItemType Directory -Force -Path (Join-Path $pcloudDir "Beastborne") | Out-Null
    New-Item -ItemType File -Force -Path (Join-Path $pcloudDir "Beastborne\01.mp3") | Out-Null
    
    New-Item -ItemType Directory -Force -Path (Join-Path $pcloudDir "Legend of Drizzt") | Out-Null
    New-Item -ItemType File -Force -Path (Join-Path $pcloudDir "Legend of Drizzt\01.mp3") | Out-Null
    
    New-Item -ItemType Directory -Force -Path (Join-Path $pcloudDir "The Hobbit") | Out-Null
    New-Item -ItemType File -Force -Path (Join-Path $pcloudDir "The Hobbit\01.mp3") | Out-Null
    
    New-Item -ItemType Directory -Force -Path (Join-Path $pcloudDir "Lord of the Rings") | Out-Null
    New-Item -ItemType File -Force -Path (Join-Path $pcloudDir "Lord of the Rings\01.mp3") | Out-Null

    Write-Output "Mock data creation completed successfully."
} catch {
    Write-Error "An error occurred during mock data creation: $_"
}
