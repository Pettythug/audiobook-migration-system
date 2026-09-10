# TASK-015: pCloud Snapshot Deduplication & Residual Audit

> **For Human Readers:** This task audits `G:\My Drive\pcloud` following the manifest ingestion in TASK-014. It identifies any remaining uncataloged audiobooks in `pcloud`, relocates them into `G:\My Drive\04_Media\Organized Audiobooks\_Uncataloged` (ensuring 100% of all audiobook media across Google Drive is consolidated in `04_Media`), sweeps the resulting empty directory shells in `pcloud` into holding cells, and updates `Media_Master_Catalog.csv`. Permanent deletions are strictly prohibited, and the `P:\` drive is completely off-limits.

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: SYSTEM_VERIFICATION_AND_MAINTENANCE
    - REQUIRED_MODEL_TIER: MEDIUM_TIER
    - ALIGNMENT_CHECK: PASS
  </GATEKEEPER>
  
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: QA_Engineer / Manager
    - SYSTEM_OVERRIDE: TEMPORARY_ALLOW(Write: ["src/Audit-PCloudResiduals.ps1", "docs/jira_tasks/plans/PLAN-015.md", "audit_log_015.md", "Manual_Review_Log.csv"]) -> EXPIRES_ON_TASK_COMPLETION
    - ABSOLUTE_BOUNDARY: STRICTLY_DENY(Access: "P:\*")
    - ZERO_DELETIONS: STRICTLY_DENY(Remove-Item)
  </ROLE_DEFINITION>
  
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-015`
    - ACTION_REQUIRED: Create branch from main, commit plan, build engine, run consolidated execution and merge.
  </ENVIRONMENT_SETUP>
  
  <OBJECTIVE>
    1. Scan `G:\My Drive\pcloud` for any residual audiobook directories.
    2. Move residual audiobooks into `G:\My Drive\04_Media\Organized Audiobooks\_Uncataloged`.
    3. Sweep emptied directory shells in `pcloud` into `G:\My Drive\pcloud\To Delete Empty Folders`.
    4. Regenerate `Media_Master_Catalog.csv` to capture the final unified inventory.
    5. Compile `audit_log_015.md` and update `docs/jira_board.md`.
  </OBJECTIVE>
  
  <RESOURCES>
    - docs/BLUEPRINT_AUDIOBOOK_MIGRATION.md
    - docs/jira_board.md
    - src/Generate-MediaCatalog.ps1
    - G:\My Drive\04_Media\Manual_Review_Log.csv
  </RESOURCES>
</TASK_EXECUTION_PROTOCOL>
```
