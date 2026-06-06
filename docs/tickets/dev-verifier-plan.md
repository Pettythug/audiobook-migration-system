# Implementation Plan - Migration Validation & Reporter

This plan details the design and implementation of `verify_migration.py` under `src/` to validate the audiobook migration. The script reads the source pCloud manifest and target Google Drive manifest, performs a comparison using path normalization and file size matching, and generates a detailed validation report. It also outlines the unit testing strategy using mock folder structures and 0-byte files under `tests/`.

## User Review Required

> [!IMPORTANT]
> The script will run entirely using standard library functions to avoid external dependencies, relying strictly on standard Python libraries like `csv`, `os`, `sys`, and `unittest`.

> [!WARNING]
> Accessing the mounted P:\ and G:\ drives is strictly blocked. All comparison operations will rely exclusively on the local CSV manifest files.

> [!CAUTION]
> Testing will be performed recursively using a mock folder structure with 0-byte dummy files under `tests/` to guarantee no live drives are accessed during test execution.

## Open Questions

There are no unresolved open questions. The requirements in `ticket-1-2.md` are fully specified.

---

## Proposed Changes

### audiobook-migration-system

#### [MODIFY] [README_entry_log.md](file:///C:/Users/wance/.gemini/antigravity/Organize%20Folders/audiobook-migration-system/README_entry_log.md)
Update the root entry log to record the addition of the new migration verifier script and unit tests.

#### [NEW] [dev-verifier-plan.md](file:///C:/Users/wance/.gemini/antigravity/Organize%20Folders/audiobook-migration-system/docs/tickets/dev-verifier-plan.md)
Create the dev verifier implementation plan file in `docs/tickets/`.

#### [NEW] [verify_migration.py](file:///C:/Users/wance/.gemini/antigravity/Organize%20Folders/audiobook-migration-system/src/verify_migration.py)
Create the migration validation script in `src/` featuring:
- **CLI Interface**: Accepts options to specify the source manifest (defaulting to `pcloud_manifest.csv`), the target manifest (defaulting to `gdrive_pcloud_manifest.csv`), and the output report path (defaulting to `migration_report.csv`).
- **Comparison Engine**:
  - Parses both manifests.
  - Normalizes path structures by lowercasing, converting separators, and stripping common prefixes (e.g., `my drive`, `pcloud`, `renamed`, `not on phone`, drive letters) to isolate relative folder paths.
  - Matches folders based on normalized relative paths.
- **Verification Logic**:
  - Compares folders in the pCloud manifest against the target manifest.
  - Checks if each source folder exists in the target manifest.
  - Verifies if the total file size matches exactly.
  - Identifies target folders that map to duplicate names, or source folders that match multiple target entries.
- **Report Generation**:
  - Outputs `migration_report.csv` listing all checked folders.
  - Flags status as:
    - `MISSING`: Folder failed to copy.
    - `SIZE_MISMATCH`: Folder exists but file sizes differ.
    - `DUPLICATE`: Folder has duplicate matches in the target.
    - `OK`: Successful match (both path and size match).
- **Terminal Output**: Prints a human-readable summary table or text showing total scanned, total matches, missing counts, size mismatch counts, and duplicate counts.

#### [NEW] [test_verify_migration.py](file:///C:/Users/wance/.gemini/antigravity/Organize%20Folders/audiobook-migration-system/tests/test_verify_migration.py)
Create unit tests under `tests/` verifying:
- Manifest reading and parsing of different CSV configurations.
- Path normalization logic across different prefix formats.
- Size matching validation.
- Identification and reporting of missing, mismatched, and duplicate folders.
- End-to-end execution of `verify_migration.py` with mock folder setups.

---

## Verification Plan

### Automated Tests
- Run tests via standard library unittest: `python -m unittest tests/test_verify_migration.py` from the project root.
- Validate that all mock tests pass 100% and correctly verify the comparison and reporting logic.

### Manual Verification
- Execute `python src/verify_migration.py --source pcloud_manifest.csv --target gdrive_pcloud_manifest.csv --output migration_report.csv` and verify the terminal output and contents of `migration_report.csv`.
