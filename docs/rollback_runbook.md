# Rollback Runbook: AudioBook Migration

This procedure must be executed immediately if a migration script incorrectly moves files, or if files in `G:\My Drive\pcloud\To Delete Audio Books` need to be restored to their original location.

## Prerequisites
- Do NOT delete the `To Delete Audio Books` folder. It is your only backup.

## Execution Steps
1. **Halt Operations**: Stop any currently running migration scripts.
2. **Identify Errors**: Review the developer's console output logs to determine which files were incorrectly moved.
3. **Restore Command**:
   Execute the following base logic to move files back to their parent directory.
   `powershell
   $stagingDir = "G:\My Drive\pcloud\To Delete Audio Books"
   $restoreDir = "G:\My Drive\pcloud"
   
   Get-ChildItem -Path $stagingDir -File | ForEach-Object {
       try {
           Move-Item -Path $_.FullName -Destination $restoreDir -ErrorAction Stop
           Write-Output "Restored: $($_.Name)"
       } catch {
           Write-Error "Restore Failed for $($_.Name): $($_.Exception.Message)"
       }
   }
   `
4. **Verify**: Check `G:\My Drive\pcloud` to confirm the files have been fully restored.
