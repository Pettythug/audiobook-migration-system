# TASK-010: Audiobookshelf Manifest Deduplication & Layout Restructuring

## 1. Executive Summary
This plan outlines the architecture and execution sequence for `src/Reorganize-AudiobookshelfManifest.ps1`, which implements a 3-tier matching algorithm to restructure the audiobook library based on `audiobookshelf_library.json`.

## 2. Script Architecture

### Parameters
*   `[CmdletBinding(SupportsShouldProcess)]`
*   `$LibraryJsonPath`
*   `$TargetDirectory`
*   `$HoldingCellDirectory`

### Safeguards
*   **Long-Path Handling:** All path enumerations and directory lookups will use the `\\?\` prefix and `[System.IO.DirectoryInfo]` to bypass 260-character `MAX_PATH` limits.
*   **Retry-with-Backoff:** A `Move-ItemWithRetry` helper function will wrap `Move-Item` to catch transient Google Drive lock exceptions, retrying at 2s, 4s, and 8s intervals.
*   **Atomic Payload Transfer:** Folders will be moved atomically via `Move-Item`, ensuring all ancillary files (`cover.jpg`, `.cue`, `.pdf`) stay with the audio tracks.
*   **Zero Deletions:** Strictly no use of `Remove-Item`. All duplicates will be safely relocated.

### Algorithm (3-Tier Match)
*   **Tier 1 (ASIN Match):** Regex `\[([B0-9A-Z]{10})\]` to extract ASINs from folder names. Exact matches against `audiobookshelf_library.json` define the canonical instance.
*   **Tier 2 (Fuzzy Match):** For folders without an ASIN, the title/author will be normalized (lowercased, punctuation stripped) and compared against the JSON library.
*   **Tier 3 (Arbitration):** If multiple folders map to the same JSON entry, the script prioritizes the one with an ASIN tag, or the highest fidelity (size/tracks). The primary original is kept, and the secondary is moved to `To Delete Audio Books`.

### Target Directory Standard
Verified items move to:
*   Series: `TargetDirectory\Author Name\Series Name\Book Title [ASIN]` (Appending Volume/Subtitle if multi-part)
*   Standalone: `TargetDirectory\Author Name\[Standalone Books]\Book Title [ASIN]`
*   Uncataloged: `TargetDirectory\_Uncataloged`

## 3. Testing & Verification
*   **Unit Tests:** A Pester test suite (`tests/test_manifest_reorganize.ps1`) constructing a mock directory tree containing edge cases (nested paths, duplicates, uncataloged) to assert a 100% pass rate.
*   **Dry-Run:** `-WhatIf` simulation against `G:\My Drive\04_Media\Organized Audiobooks` to review operations.
*   **Logging:** All operations appended to `Manual_Review_Log.csv` with rationale and paths.
