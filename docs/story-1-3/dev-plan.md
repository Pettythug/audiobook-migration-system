# Implementation Plan: Story 3 - Verified Audiobook Staging & Transactional Rollback

## Goal Description
Build `safe_move.py` in the `src` directory to securely stage verified audiobook folders from a source directory to a staging directory. It must solely target folders identified with an 'OK' status in the `migration_report.csv`. The script must support a default dry-run mode, moving empty directories to a separate location, and writing a JSON transaction log. A rollback mode must be implemented to restore files to their exact original locations using the transaction log. A comprehensive unit test suite must be provided.

## User Review Required
> [!IMPORTANT]
> The default mode for both staging and rollback operations is **dry-run**. Actual file/folder movements will require an explicit `--execute` command-line flag. 

> [!WARNING]
> No "live" cloud drives will be used during development or testing. All tests will operate on mock directories and zero-byte files created dynamically within the `tests` directory.

## Open Questions
- Is there a preferred default filename for the transaction log (e.g., `transaction_log.json`), or must it always be explicitly passed?
- When rolling back, if the destination folder becomes empty after moving files back, should we clean it up, or just restore files/folders according to the log?

## Proposed Changes

### `src` Directory

#### [NEW] [safe_move.py](file:///c:/Users/wance/.gemini/antigravity/Organize%20Folders/audiobook-migration-system/src/safe_move.py)
- **Imports:** `os`, `sys`, `csv`, `json`, `argparse`, `shutil`
- **Core Functions:**
  - `read_migration_report(report_path)`: Reads `migration_report.csv` and returns a set/list of paths where `status == 'OK'`. To accurately combine with `--source-dir`, it preferentially extracts `target_path` to preserve relative casing, falling back to `normalized_path` if absent. Reuses defensive parsing patterns from `verify_migration.py`.
  - `is_folder_empty(folder_path)`: Checks if a directory contains no files or subdirectories.
  - `move_file_or_folder(src, dst, dry_run, transaction_log)`: Safely moves an item, appending the operation to the in-memory transaction log if `dry_run` is False. If `dry_run` is True, it strictly prints the planned move.
  - `stage_verified_folders(source_dir, staging_dir, empty_dir, verified_paths, dry_run)`: 
    - Iterates over `verified_paths`.
    - Recursively moves files.
    - Tracks which directories are left empty.
    - Moves empty directories to `empty_dir`.
    - Writes the transaction log to a JSON file upon completion (if not dry-run).
  - `rollback_transaction(log_path, dry_run)`: Reads a JSON transaction log and reverses all recorded move operations. Supports dry-run.
- **CLI Arguments:**
  - `--report`: Path to `migration_report.csv` (default: `migration_report.csv` in sandbox root).
  - `--source-dir`: Base path of the source directory.
  - `--staging-dir`: Base path where verified folders will be staged.
  - `--empty-dir`: Base path where empty folders will be isolated.
  - `--execute`: Flag to actually perform the move operations.
  - `--rollback`: Path to a JSON log file to perform a rollback instead of staging.
- **Pattern Alignment:** Will utilize `argparse` for CLI, defensive exception handling, logging to `sys.stderr`, and custom path encoding for stdout, matching `manifest_scanner.py` and `verify_migration.py`.

### `tests` Directory

#### [NEW] [test_safe_move.py](file:///c:/Users/wance/.gemini/antigravity/Organize%20Folders/audiobook-migration-system/tests/test_safe_move.py)
- **Setup/Teardown:** `unittest` framework. Will dynamically create temporary mock directories (e.g., `mock_source`, `mock_staging`, `mock_empty`) and zero-byte files to represent a mock cloud drive state. Will create a mock `migration_report.csv`.
- **Test Cases:**
  - `test_dry_run_mode`: Ensures no files/folders are modified when `--execute` is missing.
  - `test_execute_verified_move`: Verifies only folders with 'OK' status are moved to the staging directory.
  - `test_ignore_non_ok_folders`: Verifies folders with 'MISSING', 'SIZE_MISMATCH', etc., are completely ignored.
  - `test_empty_folder_isolation`: Ensures folders left empty after moving files are transferred to the empty directory.
  - `test_transaction_log_creation`: Verifies the JSON log is correctly formatted and contains correct `src` and `dst` mapping.
  - `test_rollback_execution`: Verifies files and folders are perfectly restored to their original locations using the generated JSON log.
  - `test_rollback_dry_run`: Ensures rollback dry-run modifies nothing.

## Verification Plan

### Automated Tests
- Run `python -m unittest tests/test_safe_move.py` to ensure all scenarios pass with 100% simulated logic.

### Manual Verification
- Execute `safe_move.py` against a sample set of mock folders mimicking the actual folder structure.
- Validate that the terminal output matches expectations in dry-run mode.
- Execute with `--execute` and verify the `transaction_log.json` is generated correctly.
- Execute rollback with `--rollback transaction_log.json` and verify the mock structure is completely restored.
