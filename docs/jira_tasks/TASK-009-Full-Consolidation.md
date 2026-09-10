# TASK-009: Full Library Consolidation into Organized Audiobooks

> **For Human Readers:** This task consolidates all remaining audiobooks located in `G:\My Drive\04_Media\Audiobooks` (55,708 files across 161 author folders) and `G:\My Drive\04_Media\Audio Books` (839 files) into `G:\My Drive\04_Media\Organized Audiobooks`. All operations use intra-volume moves to prevent cloud trash duplication. Permanent deletions are strictly forbidden, and the `P:\` drive is completely off-limits.

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: MAINTENANCE
    - REQUIRED_MODEL_TIER: MEDIUM_TIER
    - ALIGNMENT_CHECK: IF(Active_Model NOT IN [Claude Sonnet 4.6 (Thinking), Gemini 3.1 Pro (Low), Gemini 3.5 Flash (High), Gemini 3.8 Flash (High), GPT-OSS 120B (Medium), Gemini 3.1 Pro (High), Claude Opus 4.6 (Thinking)]) THEN(HALT -> OUTPUT: "Model Alignment Error: Please switch my model to Claude Sonnet 4.6 (Thinking), Gemini 3.5 Flash (High), or Gemini 3.1 Pro to proceed.")
  </GATEKEEPER>
  
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: Sandbox_Developer
    - SYSTEM_OVERRIDE: TEMPORARY_ALLOW(Write: ["G:/My Drive/04_Media/Audiobooks/*", "G:/My Drive/04_Media/Audio Books/*", "G:/My Drive/04_Media/Organized Audiobooks/*", "Manual_Review_Log.csv", "audit_log_009.md"]) -> EXPIRES_ON_TASK_COMPLETION
    - ABSOLUTE_BOUNDARY: STRICTLY_DENY(Access: "P:\*")
  </ROLE_DEFINITION>
  
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-009`
    - ACTION_REQUIRED: Validate your working directory state before proceeding.
  </ENVIRONMENT_SETUP>
  
  <OBJECTIVE>
    1. Perform a live, intra-volume consolidation moving all author and book directories from `G:\My Drive\04_Media\Audiobooks` and `G:\My Drive\04_Media\Audio Books` into `G:\My Drive\04_Media\Organized Audiobooks`.
    2. Maintain full metadata logging in `Manual_Review_Log.csv`.
    3. Ensure zero permanent deletions and zero operations outside of `G:\My Drive\04_Media`.
  </OBJECTIVE>
  
  <RESOURCES>
    - src/Consolidate-AudioBooks.ps1
    - docs/jira_board.md
    - Manual_Review_Log.csv
  </RESOURCES>
  
  <SEQUENCE>
    1. PLAN:
       a. Read `src/Consolidate-AudioBooks.ps1` to inspect execution parameters.
       b. Formulate execution plan in `docs/jira_tasks/plans/PLAN-009.md` detailing the `-SourceDirectories` parameters and collision handling.
       c. Commit `PLAN-009.md` to git on branch `TASK-009`.
    
    2. PRE-FLIGHT CHECK:
       - Output: `[Action_Intent, View_File_Verification, Drift_Check_Alignment]` before executing any file operations or terminal commands.
    
    3. DRY-RUN SIMULATION:
       - Execute `src/Consolidate-AudioBooks.ps1` with `-WhatIf` using:
         `-SourceDirectories @('G:\My Drive\04_Media\Audiobooks', 'G:\My Drive\04_Media\Audio Books')`
         `-DestinationDirectory 'G:\My Drive\04_Media\Organized Audiobooks'`
       - Confirm zero side-effects.
    
    4. LIVE CONSOLIDATION EXECUTION:
       a. REQUIRE(Read_Before_Write).
       b. Execute `src/Consolidate-AudioBooks.ps1` without `-WhatIf`.
       c. ABSOLUTE CONSTRAINT: `STRICTLY_DENY(Remove-Item)`. No files or folders may be deleted.
       d. ABSOLUTE CONSTRAINT: `STRICTLY_DENY(Access: "P:\*")`. Never touch the P: drive.
       e. All moves must be logged with reasons to `Manual_Review_Log.csv`.
    
    5. VERIFY:
       a. Verify that `G:\My Drive\04_Media\Organized Audiobooks` has received the author and book directories.
       b. Verify that all source files were moved cleanly without error.
    
    6. AUDIT:
       - Generate `/audit_log_009.md` documenting terminal outputs, item counts moved, and verification metrics.
  </SEQUENCE>
</TASK_EXECUTION_PROTOCOL>
```
