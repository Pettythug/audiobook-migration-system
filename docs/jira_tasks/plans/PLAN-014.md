# PLAN-014: Targeted Ingestion of pCloud Audiobooks Snapshot

## 1. Executive Summary
This plan governs the implementation and execution of `src/Ingest-PCloudAudiobooks.ps1`. The engine targets the ~2,000 canonical Audiobookshelf titles currently residing across 185 author and genre directories within `G:\My Drive\pcloud`. By cross-referencing candidate folders against `docs/audiobookshelf_library.json` and indexing existing holdings in `G:\My Drive\04_Media\Organized Audiobooks`, the engine safely relocates canonical books into their target layout (`Author \ Series \ Book [ASIN]`) and quarantines duplicates to `To Delete Audio Books`.

## 2. Directory Mapping & Scope
- **Source Root:** `G:\My Drive\pcloud` (185 subdirectories including Stephen King, J.R.R. Tolkien, Brandon Sanderson, Neil Gaiman, `@MERGE_TO_ROOT`, `Drive G\Audio Books`, etc.)
- **Destination Root:** `G:\My Drive\04_Media\Organized Audiobooks`
- **Holding Cell:** `G:\My Drive\04_Media\To Delete Audio Books`
- **Audit Log:** `G:\My Drive\04_Media\Manual_Review_Log.csv`
- **Canonical Baseline:** `docs/audiobookshelf_library.json` (2,608 records)

## 3. Governance Constraints & Master Invariants
1. **Absolute Storage Boundary:** `STRICTLY_DENY(Access: "P:\*")`. Zero commands, reads, or writes targeting `P:\`.
2. **Zero-Deletion Mandate:** `STRICTLY_DENY(Remove-Item)`. Permanent deletions are prohibited. Duplicate or inferior copies are moved to `To Delete Audio Books`.
3. **Collision & Arbitration Rules:**
   - If candidate book already exists in `Organized Audiobooks`, compare track count, primary format (`.m4b` > `.mp3`), and file size.
   - Retain superior copy in `Organized Audiobooks`. Move inferior copy to `To Delete Audio Books`.
4. **Resilience Safeguards:**
   - Extended-path syntax (`\\?\`) on all filesystem operations.
   - 3-tier exponential retry backoff (2s, 4s, 8s) for Google Drive desktop sync locks.
   - Atomic payload transfer: book directories are moved as complete units with audio tracks, `cover.jpg`, and chapter cues intact.

## 4. Execution Sequence
1. **Repository Setup:** Branch `TASK-014` created from `main`.
2. **Engine Implementation:** Build `src/Ingest-PCloudAudiobooks.ps1`.
3. **Unit & Integration Testing:** Create and execute `tests/test_pcloud_ingest.ps1` in `$env:TEMP`.
4. **Dry-Run Simulation:** Execute `src/Ingest-PCloudAudiobooks.ps1 -WhatIf` to verify candidate discovery and arbitration decisions.
5. **Live Ingestion:** Execute live migration.
6. **Catalog Refresh:** Run `src/Generate-MediaCatalog.ps1` to update `Media_Master_Catalog.csv`.
7. **Audit & Merge:** Generate `audit_log_014.md`, commit deliverables, merge to `main`, and update JIRA board.
