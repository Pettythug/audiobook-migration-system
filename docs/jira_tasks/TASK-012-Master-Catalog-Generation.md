# TASK-012: Master Catalog Generation (Spreadsheet Index)

> **For Human Readers:** This task creates and executes the master catalog engine (`src/Generate-MediaCatalog.ps1`). It scans `G:\My Drive\04_Media\Organized Audiobooks`, cross-references all folders against `docs/audiobookshelf_library.json`, and exports an interactive, comprehensive spreadsheet (`G:\My Drive\04_Media\Media_Master_Catalog.csv`) that can be opened in Google Sheets or Excel to search, filter, and locate any book by Genre, Series, Author, or Title. Permanent deletions are strictly prohibited, and the `P:\` drive is completely off-limits.

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: SINGLE_FILE_FEATURE
    - REQUIRED_MODEL_TIER: MEDIUM_TIER
    - ALIGNMENT_CHECK: IF(Active_Model NOT IN [Claude Sonnet 4.6 (Thinking), Gemini 3.5 Flash (High), Gemini 3.8 Flash (High), Gemini 3.1 Pro (Low), GPT-OSS 120B (Medium), Gemini 3.1 Pro (High), Claude Opus 4.6 (Thinking)]) THEN(HALT -> OUTPUT: "Model Alignment Error: Please switch my model to Gemini 3.5 Flash (High), Gemini 3.8 Flash (High), or Claude Sonnet to proceed.")
  </GATEKEEPER>
  
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: Sandbox_Developer
    - SYSTEM_OVERRIDE: TEMPORARY_ALLOW(Write: ["src/Generate-MediaCatalog.ps1", "tests/test_catalog_generator.ps1", "G:/My Drive/04_Media/Media_Master_Catalog.csv", "audit_log_012.md"]) -> EXPIRES_ON_TASK_COMPLETION
    - ABSOLUTE_BOUNDARY: STRICTLY_DENY(Access: "P:\*")
  </ROLE_DEFINITION>
  
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-012`
    - ACTION_REQUIRED: Validate your working directory state before proceeding.
  </ENVIRONMENT_SETUP>
  
  <OBJECTIVE>
    1. Develop `src/Generate-MediaCatalog.ps1` utilizing `docs/audiobookshelf_library.json` and scanning `G:\My Drive\04_Media\Organized Audiobooks`.
    2. Generate `G:\My Drive\04_Media\Media_Master_Catalog.csv` containing complete metadata (Title, Subtitle, Series, Series Sequence, Author, Narrator, Genre(s), ASIN, Duration, Format, Size, Disk Path, Status).
    3. Ensure 100% of audiobooks on disk in `Organized Audiobooks` (both verified canonical and `_Uncataloged`) are cataloged.
    4. Ensure zero files or folders are deleted, and zero interactions occur with the P:\ drive.
  </OBJECTIVE>
  
  <RESOURCES>
    - docs/BLUEPRINT_AUDIOBOOK_MIGRATION.md
    - docs/audiobookshelf_library.json
    - docs/jira_board.md
  </RESOURCES>
  
  <SEQUENCE>
    1. PLAN:
       a. Review Section 5 of `docs/BLUEPRINT_AUDIOBOOK_MIGRATION.md` for required catalog fields.
       b. Formulate execution plan in `docs/jira_tasks/plans/PLAN-012.md` detailing the CSV schema, duration formatting, and long-path traversal.
       c. Commit `PLAN-012.md` to git on branch `TASK-012`.
    
    2. PRE-FLIGHT CHECK:
       - Output: `[Action_Intent, View_File_Verification, Drift_Check_Alignment]` before executing any file operations or terminal commands.
    
    3. ENGINE IMPLEMENTATION:
       a. Create `src/Generate-MediaCatalog.ps1`.
       b. Parameters: `-LibraryJsonPath`, `-OrganizedAudiobooksPath`, `-OutputCsvPath`.
       c. Requirements:
          - Use extended-path prefix (`\\?\`) and .NET `[System.IO.DirectoryInfo]` for directory crawling.
          - Parse `docs/audiobookshelf_library.json` into an in-memory lookup table.
          - Crawl all book leaf directories under `G:\My Drive\04_Media\Organized Audiobooks`.
          - Match by ASIN and normalized title/author.
          - Calculate directory byte size and detect primary audio format (`.m4b`, `.mp3`).
          - Format duration from seconds into `HH:MM:SS`.
          - Include relative path from `04_Media` for instant navigation.
          - Output clean UTF-8 encoded CSV.
       d. ABSOLUTE CONSTRAINT: `STRICTLY_DENY(Remove-Item)` - Zero deletions.
       e. ABSOLUTE CONSTRAINT: `STRICTLY_DENY(Access: "P:\*")` - Zero access to P:\ drive.
    
    4. TESTING & VERIFICATION:
       a. Build mock test suite `tests/test_catalog_generator.ps1`.
       b. Run tests against mock tree and assert 100% pass rate.
    
    5. LIVE EXECUTION:
       - Execute `src/Generate-MediaCatalog.ps1` live on production directory.
       - Verify `G:\My Drive\04_Media\Media_Master_Catalog.csv` is generated and valid.
    
    6. AUDIT:
       - Generate `/audit_log_012.md` detailing catalog row counts, field completeness, and verification metrics.
  </SEQUENCE>
</TASK_EXECUTION_PROTOCOL>
```
