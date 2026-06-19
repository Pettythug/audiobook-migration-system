# TASK-001: Cloud Drive Rollback

## 1. Objective
Restore the `G:\My Drive\pcloud` drive to its original state prior to executing the Content-Aware Deduplication phase.

## 2. Requirements & Inputs
- **Input:** `Sandbox_Drive\Manual_Review_Log.csv`
- **Criteria:** Filter for entries where `Reason = Empty Shell` or `Reason = Exact/Inferior Duplicate`.
- **Target Logic:** Reconstruct the original path and move the folders from `To Delete Audio Books` or `To Delete Empty Folders` back to their original `TargetFolder` paths in `G:\My Drive\pcloud`.

## 3. Strict Execution Constraints
- **File:** Draft your code in `src/Rollback-CloudDrives.ps1`.
- **Safety:** MUST USE `Move-Item -WhatIf`. Do not perform physical destructive moves.
- **Protocol:** You must strictly follow all Universal SRE rules (Try/Catch, StrictMode, Verbose/Error output only).

## 4. Output & Routing Directive
1. Write the code to `src/Rollback-CloudDrives.ps1`.
2. Commit the file to your branch.
3. **DO NOT EXECUTE THE SCRIPT.**
4. Create a new file named `docs/jira_tasks/TASK-001-Rollback-Audit.md` containing the source code you wrote for Manager Review.
5. HALT execution. Do not ask for further instructions.
