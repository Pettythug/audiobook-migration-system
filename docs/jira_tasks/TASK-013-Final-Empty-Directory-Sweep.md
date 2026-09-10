# TASK-013: Final Empty Directory Sweep & Batch 1 Formal Sign-Off

> **For Human Readers:** This task performs the final cleanup and verification of `G:\My Drive\04_Media`. It sweeps all lingering empty folder shells across legacy source directories (`Audiobooks`, `Audio Books`, `Drive E`, `Drive G`, `Drive I`, and `Organized Audiobooks`) into `To Delete Empty Folders`. It then performs an automated audit to verify that:
> 1. `To Delete Empty Folders` contains 0 files.
> 2. `Organized Audiobooks` matches the 1,801 entries in `Media_Master_Catalog.csv`.
> 3. Zero permanent deletions occurred (`Remove-Item` prohibited).
> 4. `G:\My Drive\04_Media` is 100% prepared for the user to transfer to `P:\04_Media` and wipe from `G:\`.

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: SYSTEM_VERIFICATION_AND_MAINTENANCE
    - REQUIRED_MODEL_TIER: MEDIUM_TIER
    - ALIGNMENT_CHECK: PASS
  </GATEKEEPER>
  
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: QA_Engineer / Manager
    - SYSTEM_OVERRIDE: TEMPORARY_ALLOW(Write: ["docs/jira_tasks/plans/PLAN-013.md", "audit_log_013.md", "Manual_Review_Log.csv", "src/Clean-EmptyDirectories.ps1"]) -> EXPIRES_ON_TASK_COMPLETION
    - ABSOLUTE_BOUNDARY: STRICTLY_DENY(Access: "P:\*")
    - ZERO_DELETIONS: STRICTLY_DENY(Remove-Item)
  </ROLE_DEFINITION>
  
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-013`
    - ACTION_REQUIRED: Create branch from main, formulate PLAN-013, execute sweep, audit, and merge.
  </ENVIRONMENT_SETUP>
  
  <OBJECTIVE>
    1. Sweep all empty folder shells from `04_Media` legacy roots into `G:\My Drive\04_Media\To Delete Empty Folders`.
    2. Audit `To Delete Empty Folders` to guarantee 0 payload files reside inside.
    3. Verify `G:\My Drive\04_Media\Organized Audiobooks` against `Media_Master_Catalog.csv`.
    4. Compile `audit_log_013.md` and update `docs/jira_board.md`.
    5. Issue formal Batch 1 completion sign-off.
  </OBJECTIVE>
  
  <RESOURCES>
    - docs/BLUEPRINT_AUDIOBOOK_MIGRATION.md
    - docs/jira_board.md
    - src/Clean-EmptyDirectories.ps1
    - G:\My Drive\04_Media\Media_Master_Catalog.csv
  </RESOURCES>
</TASK_EXECUTION_PROTOCOL>
```
