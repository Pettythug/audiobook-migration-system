# Audit Log - TASK-003: Deduplication Engine WhatIf Refactor

This audit log records the changes made to introduce safety dry-runs (`-WhatIf`) and relocate the deduplication script to comply with the architecture rules.

## Relocated Files
- Moved `tests/Deduplicate-CloudDrives.ps1` to `src/Deduplicate-CloudDrives.ps1`.

## Modified Files

### `src/Deduplicate-CloudDrives.ps1`
- Added `[CmdletBinding(SupportsShouldProcess)]` to the top of the parameter block.
- Wrapped folder creation (`New-Item`) for `$ToDeleteDir` and `$ToDeleteEmptyDir` in `$PSCmdlet.ShouldProcess(...)` checks.
- Wrapped folder movement (`Move-Item`) for empty shell folders and inferior duplicates in `$PSCmdlet.ShouldProcess(...)` checks.
- Enclosed the corresponding logging operations (`Out-File` append) inside the `$PSCmdlet.ShouldProcess` blocks so that dry-runs do not modify the log file.

### Test References
- Updated `tests/test_cloud_dedupe.ps1` to call the relocated script at `../src/Deduplicate-CloudDrives.ps1`.
- Updated `tests/test_singlepass.ps1` to call the relocated script at `../src/Deduplicate-CloudDrives.ps1`.
- Updated `tests/test_rollback.ps1` to call the relocated script at `src\Deduplicate-CloudDrives.ps1`.
