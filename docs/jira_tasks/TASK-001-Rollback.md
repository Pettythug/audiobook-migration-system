# TASK-001: Cloud Drive Rollback

## Objective
Restore the `G:\My Drive\pcloud` drive to its original state prior to executing the Content-Aware Deduplication phase.

## Requirements
- **Input:** `Sandbox_Drive\Manual_Review_Log.csv`
- **Criteria:** Filter for entries where `Reason = Empty Shell` or `Reason = Exact/Inferior Duplicate`.
- **Action:** Reconstruct the original path and move the folders from `To Delete Audio Books`/`To Delete Empty Folders` back to their original locations in `G:\My Drive\pcloud`.
- **Constraint:** MUST USE `Move-Item -WhatIf` to safely simulate the restoration without actually moving files yet.
- **Output:** A console log (via `Write-Verbose`) detailing exactly what would be moved.

## Acceptance Criteria
- Code executes without error.
- Try/Catch blocks handle file read issues gracefully.
- The output clearly proves that the restoration logic maps correctly to the original paths.
