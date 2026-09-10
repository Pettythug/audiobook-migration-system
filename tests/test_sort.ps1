$c = @()
$c += @{ Path = "Duplicate"; Tier = 2; Size = 10 }
$c += @{ Path = "Original"; Tier = 1; Size = 4 }
$sorted = @($c | Sort-Object Tier, @{Expression={$_.Size}; Descending=$true})
Write-Host "First: $($sorted[0].Path) Tier: $($sorted[0].Tier)"
Write-Host "Second: $($sorted[1].Path) Tier: $($sorted[1].Tier)"
