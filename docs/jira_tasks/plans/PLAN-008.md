# Goal Description
Execute the CatchUp-Sweeper task (TASK-008) to deduplicate and consolidate missed directories and create a Sweeper script that safely relocates dead empty folders bottom-up.

## Proposed Changes

### Audiobooks Catch-Up Execution
We will run:
1. `src/Deduplicate-CloudDrives.ps1`
2. `src/Consolidate-AudioBooks.ps1`
With the provided target directories.

### Sweeper Script
#### [NEW] src/Clean-EmptyDirectories.ps1
- Parameters: `$TargetDirectory`, `$HoldingCellDirectory`.
- Enforces `[CmdletBinding(SupportsShouldProcess)]` and `Set-StrictMode -Version Latest`.
- Retrieves all subdirectories using `Get-ChildItem -Directory -Recurse`.
- Sorts directories by path length descending to ensure a bottom-up (post-order) traversal.
- For each directory, checks if it is empty (no files or subdirectories left).
- Uses `Move-Item` wrapped in `try/catch` to relocate empty directories to the `$HoldingCellDirectory`.
- **Conflict Strategy**: To avoid naming conflicts in the holding cell, the relative path structure will be preserved or a GUID will be appended to the destination folder name.
- Strictly adheres to the requirement: `Remove-Item` is completely avoided.

### Sweeper Testing
#### [NEW] tests/test_sweeper.ps1
- Builds a mock tree containing both populated folders and nested empty folders.
- Runs the sweeper script.
- Asserts that all files remain untouched and only true empty folders are relocated to the holding cell.

### Audit Logging
#### [NEW] audit_log_008.md
- Will capture the console output of the test runs and the live sweep runs.

## User Review Required
Please review the plan, specifically the strategy to sort by path length descending for bottom-up processing, and let me know if it meets the requirements.

## Verification Plan
### Automated Tests
Run `tests/test_sweeper.ps1`.
### Manual Verification
Review `/audit_log_008.md` for successful live sweep operations.
