# PLAN-009: Full Library Consolidation into Organized Audiobooks

Consolidate remaining audiobooks from `G:\My Drive\04_Media\Audiobooks` and `G:\My Drive\04_Media\Audio Books` into `G:\My Drive\04_Media\Organized Audiobooks` via native intra-volume moves to prevent cloud trash duplication.

## Execution Parameters

- **Source Directories (`-SourceDirectories`):**
  - `'G:\My Drive\04_Media\Audiobooks'` (55,708 files across 161 author folders)
  - `'G:\My Drive\04_Media\Audio Books'` (839 files)
- **Destination Directory (`-DestinationDirectory`):**
  - `'G:\My Drive\04_Media\Organized Audiobooks'`
- **Logging Destination:**
  - `Manual_Review_Log.csv` (CSV audit log tracking moved folder paths and relocation reasons)
  - `audit_log_009.md` (Formal task audit log)

## Collision Handling Strategy

In accordance with `src/Consolidate-AudioBooks.ps1`:
1. The script inspects the destination directory for any directory sharing the target `$DirName`.
2. When a name collision is identified (`Test-Path -LiteralPath $DestPath`), a timestamp suffix is appended:
   `${DestPath}_${Timestamp}` where timestamp format is `yyyyMMddHHmmss`.
3. A warning is emitted and the item is relocated under the unique timestamped directory name, guaranteeing zero silent overwrites or data loss.

## Governance & Safety Mandates

- **Zero-Deletion Mandate:** `STRICTLY_DENY(Remove-Item)`. Permanent deletions are prohibited.
- **Intra-Volume Migration:** Moves are strictly intra-volume within `G:\My Drive\04_Media`, ensuring instantaneous file pointer updates and zero Google Drive cloud trash duplication.
- **Absolute Boundary Rule:** `STRICTLY_DENY(Access: "P:\*")`. The `P:\` drive is strictly off-limits.
- **Pre-Flight Check Protocol:** Every command execution and file operation must output `[Action_Intent, View_File_Verification, Drift_Check_Alignment]`.

## Verification Plan

1. **Dry-Run Simulation:**
   ```powershell
   powershell -ExecutionPolicy Bypass -Command "& 'src/Consolidate-AudioBooks.ps1' -SourceDirectories @('G:\My Drive\04_Media\Audiobooks', 'G:\My Drive\04_Media\Audio Books') -DestinationDirectory 'G:\My Drive\04_Media\Organized Audiobooks' -WhatIf"
   ```
2. **Live Consolidation:**
   ```powershell
   powershell -ExecutionPolicy Bypass -Command "& 'src/Consolidate-AudioBooks.ps1' -SourceDirectories @('G:\My Drive\04_Media\Audiobooks', 'G:\My Drive\04_Media\Audio Books') -DestinationDirectory 'G:\My Drive\04_Media\Organized Audiobooks'"
   ```
3. **Post-Execution Audit:**
   - Confirm author and book directories migrated cleanly to `G:\My Drive\04_Media\Organized Audiobooks`.
   - Verify `Manual_Review_Log.csv` has recorded move events.
   - Record outputs and item counts into `audit_log_009.md`.
