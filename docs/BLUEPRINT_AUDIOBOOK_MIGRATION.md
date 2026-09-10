# Master Architectural Blueprint: Audiobook Migration, Deduplication & Restoration

## 1. Executive Summary & Core Operating Axioms

This blueprint governs the end-to-end recovery, deduplication, organization, and cataloging of the user's master audiobook library. The overarching goal is the safe reconstruction of the user's media collection following a prior data-loss event on pCloud, operating strictly in staged, verifiable batches.

### Core Governance Constraints
1. **Absolute Storage Boundary:** `STRICTLY_DENY(Access: "P:\*")`. AI agents must never read, scan, or touch the primary `P:\` drive. All transfers between `P:\` and `G:\` are manually executed by the user.
2. **Zero-Deletion Safety Mandate:** `STRICTLY_DENY(Remove-Item)`. Permanent deletions are banned across all scripts and tasks. All empty shells and duplicate candidates are relocated to dedicated holding cells (`To Delete Empty Folders` and `To Delete Audio Books`).
3. **Ground-Truth Baseline:** `docs/audiobookshelf_library.json` (2,608 cataloged records, 2,334 Audible ASINs) serves as the canonical authority for title, author, series, volume, duration, and track count metrics.
4. **Intra-Volume Relocations:** All file operations within `G:\My Drive\` must use native intra-volume moves (`Move-Item`), preventing duplicate cloud storage usage and eliminating cloud trash flooding.

---

## 2. Directory Layout & Naming Standards

### Target Directory Standard
The physical filesystem inside `G:\My Drive\04_Media\Organized Audiobooks` shall be structured as:

```
Organized Audiobooks/
├── Author Name/
│   ├── [Standalone Books]/
│   │   └── Book Title [ASIN]/
│   │       ├── 01 - Track.mp3
│   │       ├── cover.jpg
│   │       └── metadata.json
│   └── Series Name/
│       ├── Book Title 1 [ASIN]/
│       └── Book Title 2 - Subtitle or Volume [ASIN]/
└── _Uncataloged/
    └── [Author or Source Folder]/
        └── [Uncataloged Title]/
```

* **ASIN Retention:** The Audible ASIN tag (`[B0XXXXXXXX]`) is retained in folder names to enable instant, 100% accurate metadata auto-matching when imported into Audiobookshelf.
* **Volume/Subtitle Disambiguation:** Multi-volume works sharing a common title (e.g., *Bass Reeves*) append the volume/subtitle identifier to avoid naming collisions.
* **Uncataloged Quarantine:** Any audiobook found on disk that does not match an entry in `docs/audiobookshelf_library.json` is relocated into `Organized Audiobooks\_Uncataloged` with zero contamination of the canonical author tree.

---

## 3. Deduplication & Originality Arbitration Pipeline

When candidate duplicate books are identified (e.g., one with an `[ASIN]` tag and one without, or multiple copies in legacy nested folders):

1. **Tier 1 (Canonical ASIN Matching):** Folders matching an ASIN from `audiobookshelf_library.json` are designated as the baseline canonical candidate.
2. **Tier 2 (Normalized Title & Author Fuzzy Scan):** Folders lacking an ASIN are normalized (lowercased, punctuation removed) and compared against the Audiobookshelf database.
3. **Tier 3 (Quality & Track Arbitration):**
   * **Identical Size & Tracks:** The folder with the `[ASIN]` tag is preserved as the Primary Original. The non-ASIN duplicate is moved to `G:\My Drive\04_Media\To Delete Audio Books`.
   * **Format / Bitrate Discrepancy:** The copy matching the official Audiobookshelf file count and size (or higher bitrate `.m4b` over `.mp3`) is retained. The secondary copy is quarantined in `To Delete Audio Books`.
   * **Incomplete Copies:** The complete version with full track counts is always prioritized.
   * **Logging:** Every duplicate decision and relocation reason is appended to `Manual_Review_Log.csv`.

---

## 4. Engineering Safeguards (Zero-Failure Controls)

1. **Windows Extended-Path Handling (`\\?\`):** All PowerShell scripts must interface with filesystem paths via `[System.IO.DirectoryInfo]` and long-path prefixes (`\\?\`) to eliminate `PathTooLongException` / `DirectoryNotFoundException` on legacy nested paths exceeding 260 characters.
2. **Google Drive Sync-Lock Resilience:** Every `Move-Item` and file operation must implement a 3-tier exponential backoff retry mechanism (retrying after 2s, 4s, 8s) to gracefully handle transient locks held by the Google Drive Desktop client.
3. **Ancillary Asset Retention:** Migration engines must move entire folder payloads atomically, ensuring associated `cover.jpg`, chapter `.cue` sheets, and publisher `.pdf` files remain with their audio tracks.
4. **Pre-Staging Separation:** Non-audio directories discovered in `04_Media` (`PyCharm`, `Rackspace`, `Workout Stuff` totaling ~40,000 files in `Drive G`) are safely extracted to `G:\My Drive\02_Projects` and `G:\My Drive\03_Personal` before media finalization.

---

## 5. Master Spreadsheet Catalog (`Media_Master_Catalog.csv`)

Upon completion of the deduplication and restructuring phases, an automated catalog script will generate `G:\My Drive\04_Media\Media_Master_Catalog.csv` containing:

| Field | Description | Source |
| :--- | :--- | :--- |
| **Title** | Canonical Book Title | Audiobookshelf JSON / ID3 |
| **Subtitle** | Subtitle or Volume designation | Audiobookshelf JSON |
| **Series** | Series Name | Audiobookshelf JSON |
| **Series Sequence** | Book number within the series | Audiobookshelf JSON |
| **Author** | Author Name (First Last) | Audiobookshelf JSON |
| **Narrator** | Narrator Name | Audiobookshelf JSON |
| **Genre(s)** | Comma-separated genre list | Audiobookshelf JSON |
| **ASIN / ISBN** | Audible ASIN / ISBN | Audiobookshelf JSON |
| **Duration (Hrs)** | Total playback duration formatted | Calculated from seconds |
| **File Format** | Primary extension (`.m4b`, `.mp3`) | Filesystem audit |
| **Total Size (MB)**| Total directory byte size in megabytes | Filesystem audit |
| **Disk Path** | Relative path within `Organized Audiobooks` | Filesystem audit |
| **Status** | `Verified Original` or `Uncataloged Asset` | Verification engine |

*This catalog can be imported directly into Google Sheets or Microsoft Excel for instant filtering by Genre, Series, or Title.*

---

## 6. Execution Roadmap & Ticket Phasing

### Phase 1: Batch 1 (`04_Media`) Completion (Active)
- [x] **`TASK-001` through `TASK-008`:** Rollback engine, dry-run safety audits, initial consolidation, and 7,472 empty directory sweep.
- [x] **`TASK-009`:** Full library consolidation of `Audiobooks` (55k files) and `Audio Books` into `Organized Audiobooks`.
- [x] **`TASK-010`:** Audiobookshelf Manifest Deduplication & Layout Restructuring (`Author \ Series \ Title [ASIN]`).
- [x] **`TASK-011`:** Pre-Stage Non-Media Residuals (Move `PyCharm`, `Rackspace`, `Workout Stuff` to `G:\My Drive\02_Projects` and `03_Personal`).
- [ ] **`TASK-012`:** Master Catalog Generation (`Media_Master_Catalog.csv`).
- [ ] **`TASK-013`:** Final Empty Directory Sweep & Batch 1 Formal Sign-Off.

### Phase 2: Ingestion of pCloud Audiobooks Snapshot
- [ ] **`TASK-014`:** Targeted Ingestion of ~2,000 Audiobookshelf titles from `G:\My Drive\pcloud` into `G:\My Drive\04_Media\Organized Audiobooks` using JSON manifest matching.
- [ ] **`TASK-015`:** pCloud Snapshot Deduplication & Residual Audit.

### Phase 3: Subsequent Staged Batches (Deferred)
- **Batch 2:** `02_Projects` (Development code, virtual environments, IDE configs).
- **Batch 3:** `03_Personal` (Personal records, workout data, household media).
- **Batch 4:** `01_Inbox` (Unsorted downloads and incoming assets).
- **Batch 5:** `05_Backup` & `09_Archive` (Cold storage and long-term retention).
