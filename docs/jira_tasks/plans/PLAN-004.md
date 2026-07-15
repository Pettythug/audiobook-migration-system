# PLAN-004: Production Deduplication Dry Run (-WhatIf)

Perform a non-destructive live dry run of the Deduplication Engine (`src/Deduplicate-CloudDrives.ps1`) against the real G: drive directories. Confirm that duplicate books/empty shells are identified correctly and no actual writes or deletions occur.

## Proposed Changes

No source code modifications will be performed, as the QA_Engineer role is strictly denied from modifying source code.

### Documents & Logs

#### [NEW] [PLAN-004.md](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/docs/jira_tasks/plans/PLAN-004.md)
- Define the dry-run execution plan.

#### [NEW] [audit_log_004.md](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/audit_log_004.md)
- Log the console output of the live dry run command.

---

## Verification Plan

### Manual Verification
1. Run the target PowerShell script with `-WhatIf` against the actual G: drive:
   ```powershell
   powershell -ExecutionPolicy Bypass -Command "& 'src/Deduplicate-CloudDrives.ps1' -MasterDirectory 'G:\My Drive\Audio Books' -TargetDirectories @('G:\My Drive\pcloud\Drive I', 'G:\My Drive\pcloud\Drive E', 'G:\My Drive\pcloud\Drive G') -WhatIf"
   ```
2. Verify that:
   - The script executes without red errors.
   - The output shows what changes *would* occur (WhatIf actions).
   - No modifications to the files/directories are actually made on the G: drive.
3. Save the console output to `audit_log_004.md`.
