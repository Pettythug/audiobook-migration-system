# TASK-011: Pre-Stage Non-Media Residuals into 02_Projects and 03_Personal

> **For Human Readers:** This task purifies `G:\My Drive\04_Media` of all non-media development and workout assets currently sitting in `Drive G\To Delete Empty Folders` (`PyCharm`, `Rackspace`, and `Workout Stuff` totaling 39,911 files). It moves them into their appropriate top-level staging directories on `G:\` (`G:\My Drive\02_Projects` and `G:\My Drive\03_Personal`) where they will be held until those batches are organized and permanently transferred to pCloud. Permanent deletions are strictly prohibited, and the `P:\` drive is completely off-limits.

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: MAINTENANCE
    - REQUIRED_MODEL_TIER: MEDIUM_TIER
    - ALIGNMENT_CHECK: IF(Active_Model NOT IN [Claude Sonnet 4.6 (Thinking), Gemini 3.5 Flash (High), Gemini 3.8 Flash (High), Gemini 3.1 Pro (Low), GPT-OSS 120B (Medium), Gemini 3.1 Pro (High), Claude Opus 4.6 (Thinking)]) THEN(HALT -> OUTPUT: "Model Alignment Error: Please switch my model to Gemini 3.5 Flash (High), Gemini 3.8 Flash (High), or Claude Sonnet to proceed.")
  </GATEKEEPER>
  
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: Sandbox_Developer
    - SYSTEM_OVERRIDE: TEMPORARY_ALLOW(Write: ["G:/My Drive/04_Media/Drive G/*", "G:/My Drive/02_Projects/*", "G:/My Drive/03_Personal/*", "Manual_Review_Log.csv", "audit_log_011.md"]) -> EXPIRES_ON_TASK_COMPLETION
    - ABSOLUTE_BOUNDARY: STRICTLY_DENY(Access: "P:\*")
  </ROLE_DEFINITION>
  
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-011`
    - ACTION_REQUIRED: Validate your working directory state before proceeding.
  </ENVIRONMENT_SETUP>
  
  <OBJECTIVE>
    1. Relocate non-media development directories (`PyCharm`, `Rackspace`) from `G:\My Drive\04_Media\Drive G\To Delete Empty Folders` to `G:\My Drive\02_Projects`.
    2. Relocate workout directories (`Workout Stuff`) from `G:\My Drive\04_Media\Drive G\To Delete Empty Folders` to `G:\My Drive\03_Personal`.
    3. Log all movements with reasons in `Manual_Review_Log.csv`.
    4. Ensure zero files or folders are deleted, and zero interactions occur with the P:\ drive.
  </OBJECTIVE>
  
  <RESOURCES>
    - docs/jira_board.md
    - docs/BLUEPRINT_AUDIOBOOK_MIGRATION.md
    - Manual_Review_Log.csv
  </RESOURCES>
  
  <SEQUENCE>
    1. PLAN:
       a. Inspect source folders in `G:\My Drive\04_Media\Drive G\To Delete Empty Folders`.
       b. Formulate execution plan in `docs/jira_tasks/plans/PLAN-011.md` mapping source and destination paths.
       c. Commit `PLAN-011.md` to git on branch `TASK-011`.
    
    2. PRE-FLIGHT CHECK:
       - Output: `[Action_Intent, View_File_Verification, Drift_Check_Alignment]` before executing any file operations or terminal commands.
    
    3. DRY-RUN SIMULATION (-WhatIf):
       - Simulate intra-volume moves:
         - `G:\My Drive\04_Media\Drive G\To Delete Empty Folders\PyCharm` -> `G:\My Drive\02_Projects\PyCharm`
         - `G:\My Drive\04_Media\Drive G\To Delete Empty Folders\Rackspace` -> `G:\My Drive\02_Projects\Rackspace`
         - `G:\My Drive\04_Media\Drive G\To Delete Empty Folders\Workout Stuff` -> `G:\My Drive\03_Personal\Workout Stuff`
       - Confirm destinations can be created and source files are fully intact.
    
    4. LIVE RELOCATION EXECUTION:
       a. Ensure target directories `G:\My Drive\02_Projects` and `G:\My Drive\03_Personal` exist.
       b. Execute intra-volume moves via `Move-Item`.
       c. ABSOLUTE CONSTRAINT: `STRICTLY_DENY(Remove-Item)` - Zero deletions permitted.
       d. ABSOLUTE CONSTRAINT: `STRICTLY_DENY(Access: "P:\*")` - Zero access to P:\ drive.
       e. Append all relocations with timestamps and reasons to `Manual_Review_Log.csv`.
    
    5. VERIFY:
       a. Verify that `PyCharm` and `Rackspace` now exist under `G:\My Drive\02_Projects\` with original file counts.
       b. Verify that `Workout Stuff` now exists under `G:\My Drive\03_Personal\` with original file counts.
       c. Verify that `G:\My Drive\04_Media\Drive G` is now drained of non-media assets.
    
    6. AUDIT:
       - Generate `/audit_log_011.md` documenting terminal outputs, item counts moved, and verification metrics.
  </SEQUENCE>
</TASK_EXECUTION_PROTOCOL>
```
