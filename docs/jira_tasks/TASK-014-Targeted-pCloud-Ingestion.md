# TASK-014: Targeted Ingestion of pCloud Audiobooks Snapshot

> **For Human Readers:** This task develops and executes the targeted ingestion engine (`src/Ingest-PCloudAudiobooks.ps1`). It scans `G:\My Drive\pcloud` (185 author and genre folders), cross-references candidate books against `docs/audiobookshelf_library.json`, checks existing holdings in `G:\My Drive\04_Media\Organized Audiobooks`, relocates verified canonical books into standard structure (`Author \ Series \ Title [ASIN]`), and quarantines duplicate copies to `To Delete Audio Books`. Permanent deletions are strictly prohibited, and the `P:\` drive is completely off-limits.

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: MULTI_FILE_FEATURE
    - REQUIRED_MODEL_TIER: MEDIUM_TIER
    - ALIGNMENT_CHECK: PASS
  </GATEKEEPER>
  
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: Sandbox_Developer
    - SYSTEM_OVERRIDE: TEMPORARY_ALLOW(Write: ["src/Ingest-PCloudAudiobooks.ps1", "tests/test_pcloud_ingest.ps1", "docs/jira_tasks/plans/PLAN-014.md", "audit_log_014.md", "Manual_Review_Log.csv"]) -> EXPIRES_ON_TASK_COMPLETION
    - ABSOLUTE_BOUNDARY: STRICTLY_DENY(Access: "P:\*")
    - ZERO_DELETIONS: STRICTLY_DENY(Remove-Item)
  </ROLE_DEFINITION>
  
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-014`
    - ACTION_REQUIRED: Create branch from main, commit plan, build engine, run tests, execute dry-run and live run, and merge.
  </ENVIRONMENT_SETUP>
  
  <OBJECTIVE>
    1. Develop `src/Ingest-PCloudAudiobooks.ps1` utilizing `docs/audiobookshelf_library.json`.
    2. Index existing holdings in `G:\My Drive\04_Media\Organized Audiobooks` to prevent collisions.
    3. Crawl `G:\My Drive\pcloud` and match candidate books by ASIN and normalized title/author.
    4. Move newly discovered canonical books to `G:\My Drive\04_Media\Organized Audiobooks`.
    5. Arbitrate duplicates: quarantine inferior/identical copies to `To Delete Audio Books`.
    6. Re-generate `Media_Master_Catalog.csv` via `src/Generate-MediaCatalog.ps1`.
    7. Generate `audit_log_014.md` and commit to git.
  </OBJECTIVE>
  
  <RESOURCES>
    - docs/BLUEPRINT_AUDIOBOOK_MIGRATION.md
    - docs/audiobookshelf_library.json
    - docs/jira_board.md
    - src/Reorganize-AudiobookshelfManifest.ps1
    - src/Generate-MediaCatalog.ps1
  </RESOURCES>
</TASK_EXECUTION_PROTOCOL>
```
