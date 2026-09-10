# PLAN-013: Final Empty Directory Sweep & Batch 1 Formal Sign-Off

## 1. Executive Summary
This plan governs the final sweep, verification, and formal sign-off for **Batch 1 (`04_Media`)**. With deduplication, canonical restructuring, non-media extraction, and master cataloging complete, legacy source structures in `04_Media` (`Audiobooks`, `Audio Books`, `Drive E`, `Drive G`, `Drive I`) contain only residual empty directory trees. This task sweeps all dead folder shells into the dedicated holding cell `G:\My Drive\04_Media\To Delete Empty Folders`, verifies holding cell integrity (asserting exactly 0 files), confirms the active library matches `Media_Master_Catalog.csv`, and issues the formal completion sign-off for staged migration to `P:\04_Media`.

## 2. Scope & Target Boundaries
- **Working Root:** `G:\My Drive\04_Media`
- **Legacy Source Roots to Sweep:**
  - `G:\My Drive\04_Media\Audiobooks`
  - `G:\My Drive\04_Media\Audio Books`
  - `G:\My Drive\04_Media\Drive E`
  - `G:\My Drive\04_Media\Drive G`
  - `G:\My Drive\04_Media\Drive I`
  - `G:\My Drive\04_Media\Organized Audiobooks` (empty parent shells left behind after relocations)
- **Holding Cells:**
  - `G:\My Drive\04_Media\To Delete Empty Folders` (for empty directory shells)
  - `G:\My Drive\04_Media\To Delete Audio Books` (quarantined duplicates)

## 3. Governance Constraints & Safeguards
1. **Absolute Storage Boundary:** `STRICTLY_DENY(Access: "P:\*")`. Zero commands or scans against `P:\`.
2. **Zero-Deletion Mandate:** `STRICTLY_DENY(Remove-Item)`. Banned completely. Empty folders are moved into `To Delete Empty Folders`.
3. **Holding Cell Zero-File Verification:** Before and after the sweep, `To Delete Empty Folders` is scanned to assert that `FileCount == 0`. If any file is detected, execution halts immediately.
4. **Master Catalog Alignment:** Confirm `Organized Audiobooks` matches the 1,801 entries documented in `Media_Master_Catalog.csv`.

## 4. Execution Sequence
1. **Pre-Sweep Inventory & Integrity Scan:**
   - Scan legacy roots to confirm zero media files reside within them.
   - Count empty directories queued for relocation.
2. **Bottom-Up Safe Sweep:**
   - Execute safe directory sweeper moving bottom-up from deepest leaves to roots.
   - Relocate empty directories into `To Delete Empty Folders`.
3. **Post-Sweep Verification:**
   - Verify `Audiobooks`, `Audio Books`, `Drive E`, `Drive G`, `Drive I` are completely removed or empty.
   - Audit `To Delete Empty Folders` to guarantee 0 files reside inside.
   - Verify `Organized Audiobooks` integrity.
4. **Audit & Board Update:**
   - Generate `audit_log_013.md`.
   - Update `docs/jira_board.md` marking Batch 1 as 100% COMPLETE.
   - Issue formal instructions for user to transfer `04_Media` to `P:\04_Media`.
