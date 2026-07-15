# TASK-007: Live Production Consolidation

> **For Human Readers:** This task authorizes the newly created `Consolidate-AudioBooks.ps1` script to physically execute against the production `G:\My Drive` and move all remaining unique audiobooks into the final `Organized Audiobooks` folder.

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: SINGLE_FILE_FEATURE
    - REQUIRED_MODEL_TIER: MEDIUM_TIER
  </GATEKEEPER>
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: Sandbox_Developer
    - SYSTEM_OVERRIDE: TEMPORARY_ALLOW(Write: ["G:/My Drive/04_Media/Drive I/*", "G:/My Drive/04_Media/Drive E/*", "G:/My Drive/04_Media/Drive G/*", "G:/My Drive/04_Media/Organized Audiobooks/*"]) -> EXPIRES_ON_TASK_COMPLETION
  </ROLE_DEFINITION>
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-007`
  </ENVIRONMENT_SETUP>
  <OBJECTIVE>
    Execute a LIVE run of the Consolidation Engine against the actual `04_Media` target directories to physically move the remaining unique audiobooks into `Organized Audiobooks`.
  </OBJECTIVE>
  <RESOURCES>
    - src/Consolidate-AudioBooks.ps1
  </RESOURCES>
  <SEQUENCE>
    1. READ `src/Consolidate-AudioBooks.ps1`.
    2. PLAN: Write your execution plan to `docs/jira_tasks/plans/PLAN-007.md` and commit it.
    3. MODIFY: You are DENIED from modifying any source code.
    4. VERIFY: Execute the following PowerShell command in the terminal:
       `powershell -ExecutionPolicy Bypass -Command "& 'src/Consolidate-AudioBooks.ps1' -SourceDirectories @('G:\My Drive\04_Media\Drive I', 'G:\My Drive\04_Media\Drive E', 'G:\My Drive\04_Media\Drive G') -DestinationDirectory 'G:\My Drive\04_Media\Organized Audiobooks'"`
    5. AUDIT: Read the terminal output. Confirm that the script ran successfully and moved the folders.
    6. REPORT: Generate `/audit_log_007.md` containing the terminal output and a summary of the execution results.
  </SEQUENCE>
</TASK_EXECUTION_PROTOCOL>
```
