# PLAN-012: Master Catalog Generation (Spreadsheet Index)

## 1. Executive Summary
This execution plan specifies the design, implementation, and verification of the master catalog generation engine (`src/Generate-MediaCatalog.ps1`). The engine crawls the active staged audiobook collection in `G:\My Drive\04_Media\Organized Audiobooks`, cross-references every asset against the canonical metadata database (`docs/audiobookshelf_library.json`), and generates a complete, searchable spreadsheet inventory (`G:\My Drive\04_Media\Media_Master_Catalog.csv`). This artifact provides immediate searchability, filtering, and validation across Title, Subtitle, Series, Series Sequence, Author, Narrator, Genre(s), ASIN, Duration, Format, Total Size, Disk Path, and Canonical Status.

## 2. Master Catalog Schema Specification
The generated CSV file (`Media_Master_Catalog.csv`) conforms to Section 5 of `docs/BLUEPRINT_AUDIOBOOK_MIGRATION.md` and contains the following 13 columns:

| Column Header | Description | Data Source & Transformation |
| :--- | :--- | :--- |
| **Title** | Canonical or parsed book title | Audiobookshelf JSON `metadata.title`; fallback to folder name (stripped of brackets) |
| **Subtitle** | Subtitle or volume subtitle | Audiobookshelf JSON `metadata.subtitle`; empty string if null |
| **Series** | Primary series name | Parsed from Audiobookshelf JSON `metadata.seriesName` (prefix before `#`) |
| **Series Sequence** | Book sequence within series | Extracted from Audiobookshelf JSON `metadata.seriesName` (`#(\d+(?:\.\d+)?)`) or series folder name |
| **Author** | Primary author name | Audiobookshelf JSON `metadata.authorName`; fallback to parent author folder name |
| **Narrator** | Voice narrator name(s) | Audiobookshelf JSON `metadata.narratorName`; empty string if unmatched |
| **Genre(s)** | Comma/semicolon-delimited genres | Joined string from Audiobookshelf JSON `metadata.genres` array; empty string if unmatched |
| **ASIN** | Audible ASIN or ISBN identifier | Audiobookshelf JSON `metadata.asin` / `metadata.isbn`; fallback to bracketed regex `\[([B0-9A-Z]{10})\]` |
| **Duration** | Total audio duration formatted `HH:MM:SS` | Calculated from Audiobookshelf `media.duration` (seconds); formatted via `[timespan]` with multi-day hour handling |
| **File Format** | Primary audio container extension | Audited from directory audio files (`.m4b`, `.mp3`, `.m4a`, etc.) |
| **Total Size (MB)** | Size of media files in megabytes | Summed file lengths in directory converted to MB (`[Math]::Round($bytes / 1MB, 2)`) |
| **Disk Path** | Relative path from `04_Media` | Relative path starting with `Organized Audiobooks\...` |
| **Status** | Verification and cataloging status | `Verified Original` (matched in JSON) or `Uncataloged Asset` (unmatched or in `_Uncataloged`) |

## 3. Metadata Ingestion & Cross-Referencing Architecture
1. **In-Memory Hash Lookups:**
   - Pre-parse `docs/audiobookshelf_library.json` (2,608 records, 2,334 ASINs).
   - Build `$asinLookup` hash table keyed by 10-character Audible ASIN.
   - Build `$titleAuthorLookup` hash table keyed by normalized alphanumeric string (`[a-z0-9]`).
2. **Two-Tier Matching Hierarchy:**
   - **Tier 1 (Exact ASIN Match):** Extract bracketed token `\[([B0-9A-Z]{10})\]` from directory or filename; query `$asinLookup`.
   - **Tier 2 (Normalized Title / Author Match):** Strip non-alphanumerics from folder name and match against `$titleAuthorLookup`.
   - **Uncataloged Fallback:** When no match is found, assign `Status = "Uncataloged Asset"`, parse best-effort title and author from path, and mark metadata fields accordingly.

## 4. Filesystem Crawling & Discovery Logic
1. **Extended Path Syntax (`\\?\`):** All filesystem operations use `[System.IO.DirectoryInfo]`, `[System.IO.FileInfo]`, and `\\?\` prefix to eliminate `PathTooLongException` on deeply nested paths.
2. **Book Item Boundary Resolution:**
   - Standard canonical directories: `Organized Audiobooks\Author\Series\Title [ASIN]` or `Author\[Standalone Books]\Title [ASIN]`.
   - Disc-based directories: Folders containing `CD 1`, `CD 2`, `Disc 1`, etc. are rolled up into their parent book directory.
   - Loose multi-book folders: Standalone `.m4b` files residing together in parent directories (e.g., `Audible`) are cataloged individually to prevent loss of distinct book records.
   - Uncataloged directories: Directories under `_Uncataloged` containing audio files are cataloged as individual `Uncataloged Asset` records.

## 5. Implementation Roadmap
1. **Script Creation:** Implement `src/Generate-MediaCatalog.ps1` with parameters `-LibraryJsonPath`, `-OrganizedAudiobooksPath`, `-OutputCsvPath`.
2. **Unit & Integration Testing:**
   - Create `tests/test_catalog_generator.ps1`.
   - Build mock fixture structure covering:
     - Verified canonical book with ASIN
     - Verified book with multi-disc subdirectories
     - Loose `.m4b` single-file book
     - Uncataloged book
   - Execute mock test and assert:
     - 100% of items cataloged
     - Exact column headers present
     - Correct duration formatting (`HH:MM:SS`)
     - Correct `Total Size (MB)`
     - Zero deletions performed
3. **Live Execution:**
   - Run `src/Generate-MediaCatalog.ps1` against production `G:\My Drive\04_Media\Organized Audiobooks`.
   - Output to `G:\My Drive\04_Media\Media_Master_Catalog.csv` and mirror to repository root `Media_Master_Catalog.csv`.
4. **Verification & Audit:**
   - Assert total row count >= 1,800 records.
   - Audit field completeness: Title, Author, Disk Path, Format, Size, Status.
   - Compile `audit_log_012.md`.
5. **Git Commit:** Commit all artifacts to branch `TASK-012`.

## 6. Safety Constraints & Master Invariants
- `STRICTLY_DENY(Access: "P:\*")`: Zero operations or references touching `P:\`.
- `STRICTLY_DENY(Remove-Item)`: Zero file or folder deletions.
- Read-Only Production Operations: The catalog generator reads directory trees and metadata, creating only the CSV output.
