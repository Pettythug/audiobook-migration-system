# Implementation Plan - Multi-Heuristic pCloud Scanner

This plan details the design and implementation of `manifest_scanner.py` under `src/` to recursively scan a source folder, identify audio files, classify them using multi-heuristic rules, apply folder-level majority rules, and output a CSV manifest of candidates for audiobook migration. It also outlines the unit testing strategy using mock directories and 0-byte dummy files.

## User Review Required

> [!IMPORTANT]
> The script will run entirely using standard library functions to avoid external dependencies (e.g. `mutagen`, `tinytag`), complying with the requirement to match existing patterns. We will implement simple, robust pure-Python parsers for ID3 metadata (genre, narrator) and MP4/MP3 durations.

> [!WARNING]
> Testing will be performed recursively using a mock folder structure with 0-byte dummy files under `/tests/`. We will use Python's `unittest.mock` to simulate file sizes, metadata, and durations during unit tests, ensuring no live drives are accessed.

## Open Questions

There are no unresolved open questions. The requirements in `ticket-1-1.md` are fully specified.

---

## Proposed Changes

### audiobook-migration-system

#### [MODIFY] [README_entry_log.md](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/README_entry_log.md)
Update the root entry log to record the addition of the new scanner script and unit tests.

#### [NEW] [manifest_scanner.py](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/src/manifest_scanner.py)
Create the scanner script in `src/` with the following components:
- **CLI Interface**: Uses `argparse` to accept `--source-path` (required) and `--output-csv` (optional). Defaults to a dry-run mode unless a `--write` or `--no-dry-run` flag is explicitly set.
- **Directory Traversal**: Recursively scans all folders down to leaf nodes using `os.walk`, tracking all audio files (e.g., `.mp3`, `.m4a`, `.m4b`, `.wav`, `.flac`, `.ogg`, `.aac`, `.wma`).
- **Metadata and Duration Parsers**:
  - Pure-Python ID3v2 tag parser to read `TCON` (genre), and `TPE1`/`TXXX` (narrator) tags.
  - QuickTime/MP4 `mvhd` atom parser to extract duration for `.m4a`/`.m4b` files.
  - Xing/VBRI/CBR estimator for `.mp3` duration.
  - `wave` library for `.wav` files.
- **Classification Engine**:
  - Classifies audio files into **Audiobooks**, **Music**, **System/Other**, and **Unknown**.
  - **Audiobooks**: `.m4b` extension OR duration > 45 minutes OR genre/narrator metadata indicating audiobook.
  - **Music**: Path contains keywords like "music", "playlist", "artist" OR genre is music-related.
  - **System/Other**: Path contains keywords like "assets", "help", "system".
- **Folder-Level Majority Rule**:
  - If > 50% of audio files in a folder are classified as Audiobooks, all audio files in that folder are re-classified as Audiobooks.
- **Parent Rollup and CSV Output**:
  - Groups audiobook folders and identifies their highest common parent folder containing audiobooks (without mixing in music or system directories).
  - Outputs a CSV listing `highest_common_parent`, `file_count`, `total_size_bytes`, and `migration_decision` ("Migrate" or "Review").

#### [MODIFY] [README_entry_log.md](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/src/README_entry_log.md)
Update the source folder entry log to document `manifest_scanner.py`.

#### [NEW] [test_manifest_scanner.py](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/tests/test_manifest_scanner.py)
Create unit tests under `tests/` verifying:
- Directory traversal correctness down to leaf nodes.
- Multi-heuristic classification rules.
- Folder-level majority rule overrides.
- Highest common parent folder path calculation.
- Dry-run console output and CSV file generation.

#### [MODIFY] [README_entry_log.md](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/tests/README_entry_log.md)
Update the test folder entry log to document the new unit tests.

---

## Verification Plan

### Automated Tests
- Run `pytest` or `python -m unittest discover tests` from the project root.
- Validate that all mock tests pass 100% and correctly verify the scanning and majority logic.

### Manual Verification
- Execute `python src/manifest_scanner.py --source-path tests/mock_structure` in dry-run mode and verify the console output matches expectation.
- Run with the output option to generate `pcloud_manifest.csv` and inspect its correctness.
