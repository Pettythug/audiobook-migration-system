# TASK-005: Production Deduplication Execution

> **For Human Readers:** This ticket authorizes the live execution of the Deduplication Engine. It explicitly grants temporary write access to three specific `04_Media` drives to allow the script to move duplicates into `To Delete` folders. 

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: SINGLE_FILE_FEATURE
    - REQUIRED_MODEL_TIER: MEDIUM_TIER
  </GATEKEEPER>
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: Sandbox_Developer
    - SYSTEM_OVERRIDE: TEMPORARY_ALLOW(Write: ["G:/My Drive/04_Media/Drive I/*", "G:/My Drive/04_Media/Drive E/*", "G:/My Drive/04_Media/Drive G/*"]) -> EXPIRES_ON_TASK_COMPLETION
  </ROLE_DEFINITION>
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-005`
  </ENVIRONMENT_SETUP>
  <OBJECTIVE>
    Execute a LIVE, destructive run of the Deduplication Engine against the actual `04_Media` target directories to physically move duplicate audiobooks and empty shell folders into their respective `To Delete` folders.
  </OBJECTIVE>
  <RESOURCES>
    - src/Deduplicate-CloudDrives.ps1
  </RESOURCES>
  <SEQUENCE>
    1. READ `src/Deduplicate-CloudDrives.ps1`.
    2. PLAN: Write your execution plan to `docs/jira_tasks/plans/PLAN-005.md` and commit it.
    3. MODIFY: You are DENIED from modifying any source code.
    4. VERIFY: Execute the following PowerShell command in the terminal:
       `powershell -ExecutionPolicy Bypass -Command "& 'src/Deduplicate-CloudDrives.ps1' -MasterDirectory 'G:\My Drive\04_Media\Audio Books' -TargetDirectories @('G:\My Drive\04_Media\Drive I', 'G:\My Drive\04_Media\Drive E', 'G:\My Drive\04_Media\Drive G')"`
    5. AUDIT: Read the terminal output. Confirm that the script ran successfully. Then read `Manual_Review_Log.csv` (which should have been generated in your working directory) to verify the moves were logged.
    6. REPORT: Generate `/audit_log_005.md` containing the terminal output and a summary of the CSV results.
  </SEQUENCE>
</TASK_EXECUTION_PROTOCOL>
```
