# PLAN-005: Production Deduplication Execution

Perform a live, non-dry-run execution of the Deduplication Engine (`src/Deduplicate-CloudDrives.ps1`) against the real G: drive directories. This is a destructive run that physically moves duplicate audiobooks and empty shell folders into `To Delete Audio Books` and `To Delete Empty Folders` within each target drive.

## Proposed Changes

No source code modifications will be performed, as Sandbox_Developer is denied from modifying any source code for this ticket.

### Documents & Logs

#### [NEW] [PLAN-005.md](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/docs/jira_tasks/plans/PLAN-005.md)
- Define the live production deduplication execution plan.

#### [NEW] [audit_log_005.md](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/audit_log_005.md)
- Log the console output and results of the live execution.

---

## Verification Plan

### Manual Verification
1. Run the target PowerShell script against the actual G: drive:
   ```powershell
   powershell -ExecutionPolicy Bypass -Command "& 'src/Deduplicate-CloudDrives.ps1' -MasterDirectory 'G:\My Drive\04_Media\Audio Books' -TargetDirectories @('G:\My Drive\04_Media\Drive I', 'G:\My Drive\04_Media\Drive E', 'G:\My Drive\04_Media\Drive G')"
   ```
2. Verify that:
   - The script runs successfully.
   - Files are moved into `To Delete Audio Books` and `To Delete Empty Folders`.
   - `Manual_Review_Log.csv` is updated/generated and contains the log of moves.
3. Save the console output to `audit_log_005.md`.
