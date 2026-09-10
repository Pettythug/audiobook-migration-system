# TASK-010: Audiobookshelf Manifest Deduplication & Layout Restructuring

> **For Human Readers:** This task creates and executes the manifest-driven deduplication and reorganization engine (`src/Reorganize-AudiobookshelfManifest.ps1`). It parses `docs/audiobookshelf_library.json` as the ground-truth authority, matches all audiobooks currently inside `G:\My Drive\04_Media\Organized Audiobooks`, restructures verified originals into canonical `Author Name \ Series Name \ Book Title [ASIN]` folders, relocates confirmed duplicates to `To Delete Audio Books`, and quarantines uncataloged books into `_Uncataloged`. Permanent deletions are strictly prohibited, and the `P:\` drive is completely off-limits.

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: MULTI_FILE_Refactoring
    - REQUIRED_MODEL_TIER: HIGH_TIER
    - ALIGNMENT_CHECK: IF(Active_Model NOT IN [Claude Opus 4.6 (Thinking), Gemini 3.1 Pro (High), Claude Sonnet 4.6 (Thinking), Gemini 3.5 Flash (High), Gemini 3.8 Flash (High), Gemini 3.1 Pro (Low), GPT-OSS 120B (Medium)]) THEN(HALT -> OUTPUT: "Model Alignment Error: Please switch my model to Gemini 3.1 Pro (High), Gemini 3.8 Flash (High), or Claude to proceed.")
  </GATEKEEPER>
  
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: Sandbox_Developer
    - SYSTEM_OVERRIDE: TEMPORARY_ALLOW(Write: ["src/Reorganize-AudiobookshelfManifest.ps1", "tests/test_manifest_reorganize.ps1", "G:/My Drive/04_Media/Organized Audiobooks/*", "G:/My Drive/04_Media/To Delete Audio Books/*", "Manual_Review_Log.csv", "audit_log_010.md"]) -> EXPIRES_ON_TASK_COMPLETION
    - ABSOLUTE_BOUNDARY: STRICTLY_DENY(Access: "P:\*")
  </ROLE_DEFINITION>
  
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-010`
    - ACTION_REQUIRED: Validate your working directory state before proceeding.
  </ENVIRONMENT_SETUP>
  
  <OBJECTIVE>
    1. Develop `src/Reorganize-AudiobookshelfManifest.ps1` incorporating the 3-Tier Match Algorithm and the 5 Engineering Safeguards defined in `docs/BLUEPRINT_AUDIOBOOK_MIGRATION.md`.
    2. Restructure verified original audiobooks into `G:\My Drive\04_Media\Organized Audiobooks\Author Name\[Series Name\]Book Title [ASIN]`.
    3. Relocate redundant duplicate copies into `G:\My Drive\04_Media\To Delete Audio Books`.
    4. Relocate uncataloged books into `G:\My Drive\04_Media\Organized Audiobooks\_Uncataloged`.
    5. Maintain complete operation logging in `Manual_Review_Log.csv`.
  </OBJECTIVE>
  
  <RESOURCES>
    - docs/BLUEPRINT_AUDIOBOOK_MIGRATION.md
    - docs/audiobookshelf_library.json
    - docs/jira_board.md
    - Manual_Review_Log.csv
  </RESOURCES>
  
  <SEQUENCE>
    1. PLAN:
       a. Read `docs/BLUEPRINT_AUDIOBOOK_MIGRATION.md` (Sections 2, 3, and 4) to review the exact algorithm and safeguards.
       b. Formulate execution plan in `docs/jira_tasks/plans/PLAN-010.md` detailing the script architecture, regex parsing for ASINs, retry logic, and long-path handling.
       c. Commit `PLAN-010.md` to git on branch `TASK-010`.
    
    2. PRE-FLIGHT CHECK:
       - Output: `[Action_Intent, View_File_Verification, Drift_Check_Alignment]` before executing any file operations or terminal commands.
    
    3. ENGINE IMPLEMENTATION:
       a. Create `src/Reorganize-AudiobookshelfManifest.ps1`.
       b. Parameters: `-LibraryJsonPath`, `-TargetDirectory`, `-HoldingCellDirectory`, `-SupportsShouldProcess`.
       c. Implement Mandatory Safeguards:
          - Extended-path prefix (`\\?\`) and .NET `[System.IO.DirectoryInfo]` for all filesystem traversal to eliminate 260-character MAX_PATH exceptions.
          - Google Drive lock retry-with-backoff (3 retries: 2s, 4s, 8s intervals).
          - Atomic payload transfer (preserve `cover.jpg`, `.cue`, `.pdf`, `.json` with audio tracks).
          - Disambiguation: Append Volume/Subtitle to titles for multi-part books sharing identical titles.
       d. Implement 3-Tier Match & Resolution:
          - Tier 1: Canonical ASIN match (`[B0XXXXXXXX]`).
          - Tier 2: Normalized Title & Author match.
          - Tier 3: Quality & track arbitration. Retain Primary Original in canonical layout; move secondary duplicate to `To Delete Audio Books`.
          - Non-matching audio folders move to `_Uncataloged`.
       e. ABSOLUTE CONSTRAINT: `STRICTLY_DENY(Remove-Item)` - Zero deletions.
       f. ABSOLUTE CONSTRAINT: `STRICTLY_DENY(Access: "P:\*")` - Zero access to P:\ drive.
    
    4. TESTING & VERIFICATION:
       a. Create `tests/test_manifest_reorganize.ps1` building a mock tree with:
          - ASIN-tagged book.
          - Non-ASIN duplicate of the same book.
          - Deeply nested path (> 260 chars).
          - Multi-volume book sharing title.
          - Uncataloged dummy book.
       b. Execute unit test in mock environment and assert 100% pass rate.
    
    5. DRY-RUN SIMULATION (-WhatIf):
       - Execute `src/Reorganize-AudiobookshelfManifest.ps1` with `-WhatIf` against `G:\My Drive\04_Media\Organized Audiobooks`.
       - Confirm zero errors and zero side-effects.
    
    6. LIVE REORGANIZATION EXECUTION:
       - Execute `src/Reorganize-AudiobookshelfManifest.ps1` live against `G:\My Drive\04_Media\Organized Audiobooks`.
       - Append all movements with reasons to `Manual_Review_Log.csv`.
    
    7. POST-EXECUTION AUDIT:
       a. Verify that canonical author/series folders are established.
       b. Verify that `_Uncataloged` received non-matching folders safely.
       c. Verify that `To Delete Audio Books` holds duplicate copies with 0 original tracks lost.
       d. Generate `/audit_log_010.md` detailing execution metrics, counts, and verification results.
  </SEQUENCE>
</TASK_EXECUTION_PROTOCOL>
```
