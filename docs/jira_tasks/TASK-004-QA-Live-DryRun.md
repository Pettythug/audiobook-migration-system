# TASK-004: Production Deduplication Dry Run (-WhatIf)

> **For Human Readers:** The Developer has successfully refactored `Deduplicate-CloudDrives.ps1` to support `-WhatIf` non-destructive executions. The QA Engineer must now execute a live dry-run against the real `G:` drive to prove that the engine works against real data without deleting anything.

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: SINGLE_FILE_FEATURE
    - REQUIRED_MODEL_TIER: MEDIUM_TIER
  </GATEKEEPER>
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: QA_Engineer
    - SYSTEM_OVERRIDE: ALLOW(Read: ["G:/My Drive/*"]) DENY(Write_Source_Code)
  </ROLE_DEFINITION>
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-004`
  </ENVIRONMENT_SETUP>
  <OBJECTIVE>
    Execute a LIVE `-WhatIf` dry run of the Deduplication Engine against the actual G: drive target directories to verify there are no pipeline or pathing errors in the live environment.
  </OBJECTIVE>
  <RESOURCES>
    - src/Deduplicate-CloudDrives.ps1
  </RESOURCES>
  <SEQUENCE>
    1. READ `src/Deduplicate-CloudDrives.ps1`.
    2. PLAN: Write your execution plan to `docs/jira_tasks/plans/PLAN-004.md` and commit it.
    3. MODIFY: You are DENIED from modifying any source code.
    4. VERIFY: Execute the following PowerShell command in the terminal:
       `powershell -ExecutionPolicy Bypass -Command "& 'src/Deduplicate-CloudDrives.ps1' -MasterDirectory 'G:\My Drive\Audio Books' -TargetDirectories @('G:\My Drive\pcloud\Drive I', 'G:\My Drive\pcloud\Drive E', 'G:\My Drive\pcloud\Drive G') -WhatIf"`
    5. AUDIT: Read the terminal output. Confirm that the script ran successfully, identified duplicates (if any), and ONLY performed `WhatIf` operations without throwing any red PowerShell errors. Generate `/audit_log_004.md` containing the terminal output.
  </SEQUENCE>
</TASK_EXECUTION_PROTOCOL>
```
