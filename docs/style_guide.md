# PowerShell Style & Logging Guide

All PowerShell scripts in this project must adhere strictly to these professional standards:

## 1. Naming Conventions
- Functions must use the standard `Verb-Noun` syntax (e.g., `Compare-AudioBooks`, `Move-DuplicateFile`).
- Variables must be `camelCase` (e.g., ``, ``).

## 2. Error Handling
- EVERY critical file operation (reading CSVs, moving files, iterating folders) must be wrapped in a `Try-Catch` block.
- Example:
`powershell
try {
    Move-Item -Path $source -Destination $target -ErrorAction Stop
} catch {
    Write-Error "Failed to move file: $($_.Exception.Message)"
}
`

## 3. Logging & Output
- Use `Write-Output` for standard informational progress.
- Use `Write-Warning` for non-critical issues (e.g., "File not found in manifest").
- Use `Write-Error` ONLY inside `catch` blocks for fatal failures.
- Do not use `Write-Host` unless explicitly requesting user input (which is forbidden in automated scripts anyway).
