# PLAN-015: pCloud Snapshot Deduplication & Residual Audit

## 1. Executive Summary
This plan governs the execution of `src/Audit-PCloudResiduals.ps1` to complete Phase 2. Following the manifest-driven ingestion of canonical titles in TASK-014, `G:\My Drive\pcloud` contains:
1. Residual non-manifest audiobook assets (indie audiobooks, unindexed multi-disc audio, etc.) that need to be consolidated into `G:\My Drive\04_Media\Organized Audiobooks\_Uncataloged`.
2. Emptied folder shells resulting from the 1,522 relocations in TASK-014, to be swept into `G:\My Drive\pcloud\To Delete Empty Folders`.
3. Non-media directories (`Documents`, `Java`, `PyCharm`, etc.) which will be preserved in `pcloud` for subsequent project and personal batches.

## 2. Directory Mapping & Scope
- **Source Root:** `G:\My Drive\pcloud`
- **Destination for Residual Audio:** `G:\My Drive\04_Media\Organized Audiobooks\_Uncataloged`
- **Holding Cell for Empty Shells:** `G:\My Drive\pcloud\To Delete Empty Folders`
- **Holding Cell for Duplicates:** `G:\My Drive\04_Media\To Delete Audio Books`
- **Non-Media Directories to Preserve in pCloud:** `pcloud\Drive G\Documents`, `Downloads`, `Java`, `PyCharm`, `AirflowHome`, etc.

## 3. Governance Constraints & Safeguards
1. **Absolute Storage Boundary:** `STRICTLY_DENY(Access: "P:\*")`. Zero interaction with `P:\`.
2. **Zero-Deletion Mandate:** `STRICTLY_DENY(Remove-Item)`. Permanent deletions are prohibited.
3. **Non-Media Isolation:** Folders without audio tracks (development environments, personal documents) remain strictly intact within `pcloud` and are NOT moved into `04_Media`.
4. **Resilience Safeguards:** Long-path syntax (`\\?\`) and 3-tier exponential retry backoff on all operations.

## 4. Execution Sequence
1. **Repository Setup:** Check out branch `TASK-015` from `main`.
2. **Engine Implementation:** Build `src/Audit-PCloudResiduals.ps1`.
3. **Consolidated Live Execution:**
   - Discover residual audio directories in `pcloud`.
   - Relocate residual audio into `04_Media\Organized Audiobooks\_Uncataloged`.
   - Sweep dead empty folder shells into `pcloud\To Delete Empty Folders`.
   - Regenerate `Media_Master_Catalog.csv`.
4. **Audit & Board Update:**
   - Generate `audit_log_015.md`.
   - Commit all deliverables, merge to `main`, and update `docs/jira_board.md`.
