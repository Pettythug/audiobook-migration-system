# TASK-008: Audiobooks Catch-Up & Empty Folder Sweeper

> **For Human Readers:** This task catches up the missed `Audiobooks` and `Audio Books` directories by running them through the deduplication and consolidation engines. It then creates a recursive Sweeper to relocate all dead empty folders from `04_Media` to a holding cell. **No files or folders will be deleted.**

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: MULTI_FILE_Refactoring
    - REQUIRED_MODEL_TIER: HIGH_TIER
  </GATEKEEPER>
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: Sandbox_Developer
    - SYSTEM_OVERRIDE: TEMPORARY_ALLOW(Write: ["G:/My Drive/04_Media/*", "/src/Clean-EmptyDirectories.ps1", "/tests/test_sweeper.ps1"])
  </ROLE_DEFINITION>
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-008`
  </ENVIRONMENT_SETUP>
  <OBJECTIVE>
    1. Deduplicate `Audiobooks` against `Audio Books`.
    2. Consolidate both `Audiobooks` and `Audio Books` into `Organized Audiobooks`.
    3. Create and execute a Sweeper script that recursively relocates 0-file empty folders across all of `04_Media` into a holding cell.
  </OBJECTIVE>
  <RESOURCES>
    - src/Deduplicate-CloudDrives.ps1
    - src/Consolidate-AudioBooks.ps1
    - src/Clean-EmptyDirectories.ps1 (To be created)
    - tests/test_sweeper.ps1 (To be created)
  </RESOURCES>
  <SEQUENCE>
    1. PLAN: Write your execution plan to `docs/jira_tasks/plans/PLAN-008.md` and commit it.
    
    2. CATCH-UP EXECUTION:
       a. Run `src/Deduplicate-CloudDrives.ps1` with `-MasterDirectory "G:\My Drive\04_Media\Audio Books"` and `-TargetDirectories @("G:\My Drive\04_Media\Audiobooks")`.
       b. Run `src/Consolidate-AudioBooks.ps1` with `-SourceDirectories @("G:\My Drive\04_Media\Audiobooks", "G:\My Drive\04_Media\Audio Books")` and `-DestinationDirectory "G:\My Drive\04_Media\Organized Audiobooks"`.
    
    3. SWEEPER CREATION:
       a. Create `src/Clean-EmptyDirectories.ps1`.
       b. Accepts `-TargetDirectory` and `-HoldingCellDirectory`.
       c. Recursively scans `-TargetDirectory` ALL THE WAY DOWN to the deepest leaf node. 
       d. Must evaluate bottom-up (post-order traversal) so parent directories become empty if their children are relocated.
       e. ABSOLUTE CONSTRAINT: You are STRICTLY_DENIED from using `Remove-Item` or deleting anything. If a folder contains zero files (and zero subfolders after bottom-up evaluation), use `Move-Item` to relocate it to the `-HoldingCellDirectory`.
       f. Implement `[CmdletBinding(SupportsShouldProcess)]` for `-WhatIf` testing.
    
    4. SWEEPER TESTING:
       a. Write `tests/test_sweeper.ps1` to build a mock tree, run the sweeper, and assert that files are NEVER touched and empty folders are safely moved.
       b. Execute the test.
    
    5. LIVE SWEEP:
       a. Execute `src/Clean-EmptyDirectories.ps1` live on `"G:\My Drive\04_Media"`, using `"G:\My Drive\04_Media\To Delete Empty Folders"` as the holding cell.
    
    6. AUDIT: Generate `/audit_log_008.md` detailing the test success and the terminal outputs of all live runs.
  </SEQUENCE>
</TASK_EXECUTION_PROTOCOL>
```
