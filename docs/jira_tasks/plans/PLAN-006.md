# PLAN-006: Consolidate Unique Audiobooks

Create a PowerShell consolidation script `src/Consolidate-AudioBooks.ps1` to move remaining unique audiobook folders from specific target source directories into a unified `Organized Audiobooks` destination directory. 

## Proposed Changes

### Core Scripts

#### [NEW] [Consolidate-AudioBooks.ps1](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/src/Consolidate-AudioBooks.ps1)
- Add `[CmdletBinding(SupportsShouldProcess)]` to support `-WhatIf` and `-Confirm` flags.
- Enforce strict rules via `Set-StrictMode -Version Latest`.
- Accept parameters:
  - `[string[]]$SourceDirectories`: Directories to scan for unique audiobook folders.
  - `[string]$DestinationDirectory`: Target directory to move the consolidated folders into.
- For each directory in `SourceDirectories`:
  - Check if the source directory exists.
  - Fetch all top-level directories within the source directory (ignoring system folders and specific delete folders like "To Delete Audio Books" or "To Delete Empty Folders").
  - Perform standard `Move-Item` to the `DestinationDirectory`.
- Wrap all `New-Item` (destination folder creation) and `Move-Item` calls inside `$PSCmdlet.ShouldProcess` blocks.
- Perform all file I/O operations inside `try/catch` blocks for robust error handling.

### Tests

#### [NEW] [test_consolidate.ps1](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/tests/test_consolidate.ps1)
- Write a mock test suite that:
  - Creates a mock environment (mock source directories, files, and destination directory).
  - Simulates the execution of `src/Consolidate-AudioBooks.ps1` with and without `-WhatIf`.
  - Asserts that folders are correctly moved when executed normally.
  - Asserts that folders remain untouched during a `-WhatIf` run.
  - Cleans up the mock folders after test completion.

### Audit & Log

#### [NEW] [audit_log_006.md](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/audit_log_006.md)
- Create `/audit_log_006.md` detailing the test run results.

---

## Verification Plan

### Automated Tests
1. Run the test consolidation script:
   `powershell -ExecutionPolicy Bypass -File C:\Users\wance\Documents\Git\audiobook-migration-system\tests\test_consolidate.ps1`

### Manual Verification
- Verify that no duplicate cloud files or deletion cycles occur on the destination target by verifying that native renames (`Move-Item` on same volume) are executed.
