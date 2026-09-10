# Enterprise Staged Migration & Reorganization - JIRA Master Board

> **Master Architecture Reference:** See [docs/BLUEPRINT_AUDIOBOOK_MIGRATION.md](BLUEPRINT_AUDIOBOOK_MIGRATION.md) for full algorithmic specifications, storage axioms, and data structures.

---

## 1. System Operating Axioms & Governance
- **Staged Batch Architecture:** Operations are strictly performed in isolated batches staged on `G:\My Drive\`.
- **Absolute Boundary Rule:** `STRICTLY_DENY(Access: "P:\*")`. AI agents must NEVER interact with or touch the `P:\` drive. All transfers between `P:\` and `G:\` are manually controlled by the user.
- **Zero-Deletion Safety Mandate:** `STRICTLY_DENY(Remove-Item)`. Permanent deletions are prohibited. All dead shells, empty folders, and duplicate candidates are relocated to dedicated holding cells (`To Delete Empty Folders` and `To Delete Audio Books`).
- **Ground-Truth Authority:** `docs/audiobookshelf_library.json` (2,608 cataloged records, 2,334 Audible ASINs) serves as the canonical baseline for identifying verified original audiobooks, canonical titles, authors, series, and ASINs.
- **Target Organization Standard:** `Author Name \ Series Name \ Book Title [ASIN]`.
- **Quarantine Protocol:** Any audiobook found on disk that does not match the Audiobookshelf JSON is safely isolated into `Organized Audiobooks\_Uncataloged`.

---

## 2. Ledger of Completed Work (Sprint History)

| Task ID | Task Title | Primary Deliverable | Audit / Artifacts | Status |
| :--- | :--- | :--- | :--- | :--- |
| **`TASK-001`** | Rollback Engine Implementation | `src/Rollback-CloudDrives.ps1` | `docs/jira_tasks/TASK-001-Rollback.md` | **COMPLETED** |
| **`TASK-002`** | Physical Dry-Run Stress Testing | Mock testing suite | `tests/test_rollback.ps1` | **COMPLETED** |
| **`TASK-003`** | Engine Hardening & Relocation | `$PSCmdlet.ShouldProcess` added | `src/Deduplicate-CloudDrives.ps1`, `audit_log_003.md` | **COMPLETED** |
| **`TASK-004`** | Production `-WhatIf` Safety Audit | 24k operations dry-run verified | `docs/jira_tasks/plans/PLAN-004.md`, `audit_log_004.md` | **COMPLETED** |
| **`TASK-005`** | Production Deduplication Run | Relocated initial duplicates | `Manual_Review_Log.csv`, `audit_log_005.md` | **COMPLETED** |
| **`TASK-006`** | Consolidation Engine Build | `src/Consolidate-AudioBooks.ps1` | Native same-volume moves, `tests/test_consolidate.ps1` | **COMPLETED** |
| **`TASK-007`** | Live Initial Consolidation | Moved `Drive I` & `Drive E` into `Organized` | `docs/jira_tasks/plans/PLAN-007.md`, `audit_log_007.md` | **COMPLETED** |
| **`TASK-008`** | Safe Sweeper Build & Catch-Up Sweep | `src/Clean-EmptyDirectories.ps1` | 7,472 empty directories moved to holding cell; 0 files touched | **COMPLETED** |
| **`CORP-001`** | Corporate Template Standardization | `corporate-standards/TASK_TEMPLATE.md` | Unified enterprise task template with Pre-Flight checks | **COMPLETED** |
| **`TASK-009`** | Full Library Consolidation | Consolidated `Audiobooks` (55k files) into `Organized Audiobooks` | 161 directories moved; `Manual_Review_Log.csv`, `audit_log_009.md` | **COMPLETED** |
| **`TASK-010`** | Audiobookshelf Manifest Deduplication | Restructured canonical layout & quarantined duplicates | `src/Reorganize-AudiobookshelfManifest.ps1`, `audit_log_010.md` | **COMPLETED** |

---

## 3. Active Epic: Batch 1 — `04_Media` Reorganization & Reconciliation

**Goal:** Completely consolidate, deduplicate, organize, and catalog all assets within `G:\My Drive\04_Media` into a verified state with an exportable spreadsheet inventory, preparing it for clean restoration.

### Active & Upcoming Ticket Sequence

### [COMPLETED] TASK-010: Audiobookshelf Manifest Deduplication & Layout Restructuring
- **Status:** COMPLETED on branch `TASK-010` and merged into `main`. Canonical layouts generated, duplicates quarantined to `To Delete Audio Books`, uncataloged assets isolated in `_Uncataloged`.

### [READY] TASK-011: Pre-Stage Non-Media Residuals
- **Assigned Role:** Sandbox_Developer (High Tier)
- **Scope:** Parse `docs/audiobookshelf_library.json`. Scan `G:\My Drive\04_Media\Organized Audiobooks`.
- **Engineering Requirements:**
  - Extended path handling (`\\?\`) via .NET to prevent 260-character MAX_PATH errors.
  - Google Drive sync-lock retry-with-backoff logic (3 retries, 2s backoff).
  - 3-tier matching: Canonical ASIN matching, normalized title/author fuzzy scan, track/byte-size arbitration.
  - Relocate verified books into `Author Name \ Series Name \ Book Title [ASIN]`.
  - Quarantine non-matching books into `Organized Audiobooks\_Uncataloged`.
  - Relocate confirmed duplicate copies to `G:\My Drive\04_Media\To Delete Audio Books`.

### [PENDING] TASK-011: Pre-Stage Non-Media Residuals
- **Assigned Role:** Sandbox_Developer (Medium Tier)
- **Scope:** Isolate non-media directories currently in `Drive G\To Delete Empty Folders` (`PyCharm`, `Rackspace`, `Workout Stuff` totaling 39,911 files) out of `04_Media`.
- **Action:** Move them into root pre-staging directories: `G:\My Drive\02_Projects` and `G:\My Drive\03_Personal`.

### [PENDING] TASK-012: Master Catalog Generation (Spreadsheet Index)
- **Assigned Role:** Sandbox_Developer (Low/Medium Tier)
- **Scope:** Generate `Media_Master_Catalog.csv` in `G:\My Drive\04_Media\`.
- **Fields:** Title, Subtitle, Series, Series Sequence, Author, Narrator, Genre(s), ASIN, Duration, Format, Total Size (MB), Disk Path, Status.
- **Output:** Importable into Google Sheets / Excel for instant searching and browsing.

### [PENDING] TASK-013: Final Empty Directory Sweep & Batch 1 Sign-Off
- **Assigned Role:** QA_Engineer / Manager
- **Scope:** Run `Clean-EmptyDirectories.ps1` across `04_Media` to sweep newly emptied source directories into `To Delete Empty Folders`.
- **Verification:** Confirm 0 files in holding cell, verify all media assets accounted for in catalog, formal Batch 1 sign-off.

---

## 4. Phase 2: Ingestion of pCloud Audiobooks Snapshot
- **`TASK-014`:** Targeted Ingestion of ~2,000 Audiobookshelf titles from `G:\My Drive\pcloud` into `G:\My Drive\04_Media\Organized Audiobooks` using JSON manifest matching.
- **`TASK-015`:** pCloud Snapshot Deduplication & Residual Audit.

---

## 5. Backlog: Future Staged Batches (Post-Batch 1)
*These batches remain completely deferred until Batch 1 is 100% completed and signed off:*
- **Batch 2:** `02_Projects` (Development code, virtual environments, IDE configs)
- **Batch 3:** `03_Personal` (Personal records, workout data, household media)
- **Batch 4:** `01_Inbox` (Unsorted downloads and incoming assets)
- **Batch 5:** `05_Backup` & `09_Archive` (Cold storage and long-term retention)
