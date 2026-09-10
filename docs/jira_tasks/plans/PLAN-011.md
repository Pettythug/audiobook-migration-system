# TASK-011: Pre-Stage Non-Media Residuals into 02_Projects and 03_Personal

## 1. Executive Summary
This plan governs the isolation and pre-staging of non-media residual directories currently residing within `G:\My Drive\04_Media\Drive G\To Delete Empty Folders`. Specifically, the development directories (`PyCharm`, `Rackspace`) and workout assets (`Workout Stuff`), totaling 39,910 files, are to be relocated into their respective top-level staging directories on `G:\` (`G:\My Drive\02_Projects` and `G:\My Drive\03_Personal`).

## 2. Directory Mapping & Baseline Inventory

### Source Directory
`G:\My Drive\04_Media\Drive G\To Delete Empty Folders`

### Target Mappings
| Asset Name | Source Path | Target Path | Files Baseline | Directories Baseline |
| :--- | :--- | :--- | :--- | :--- |
| **PyCharm** | `G:\My Drive\04_Media\Drive G\To Delete Empty Folders\PyCharm` | `G:\My Drive\02_Projects\PyCharm` | 38,717 | 6,769 |
| **Rackspace** | `G:\My Drive\04_Media\Drive G\To Delete Empty Folders\Rackspace` | `G:\My Drive\02_Projects\Rackspace` | 1,175 | 160 |
| **Workout Stuff** | `G:\My Drive\04_Media\Drive G\To Delete Empty Folders\Workout Stuff` | `G:\My Drive\03_Personal\Workout Stuff` | 18 | 2 |
| **Total** | | | **39,910** | **6,931** |

## 3. Governance Constraints & Safeguards
1. **Absolute Storage Boundary:** `STRICTLY_DENY(Access: "P:\*")`. Zero interaction with the `P:\` drive.
2. **Zero-Deletion Safety Mandate:** `STRICTLY_DENY(Remove-Item)`. No files or folders will be permanently deleted.
3. **Intra-Volume Relocation:** Movements are intra-volume on `G:\` via `Move-Item`, avoiding duplicate storage usage or cloud trash overhead.
4. **Target Pre-Creation:** Target parent directories `G:\My Drive\02_Projects` and `G:\My Drive\03_Personal` will be created if not already present.
5. **Audit Logging:** Every relocation action will be appended to `Manual_Review_Log.csv` with source, destination, timestamp, and rationale.

## 4. Execution Sequence
1. **Target Directory Setup:** Ensure `G:\My Drive\02_Projects` and `G:\My Drive\03_Personal` exist.
2. **Dry-Run Simulation:** Execute PowerShell `Move-Item` with `-WhatIf` to simulate movements and verify path syntax.
3. **Live Execution:** Execute `Move-Item` for each of the three directories into their target locations.
4. **Log Updates:** Append records for PyCharm, Rackspace, and Workout Stuff to `Manual_Review_Log.csv`.
5. **Verification:**
   - Recursively count files in `G:\My Drive\02_Projects\PyCharm` (expect 38,717).
   - Recursively count files in `G:\My Drive\02_Projects\Rackspace` (expect 1,175).
   - Recursively count files in `G:\My Drive\03_Personal\Workout Stuff` (expect 18).
   - Verify `G:\My Drive\04_Media\Drive G\To Delete Empty Folders` is drained of non-media assets.
6. **Audit & Commit:**
   - Generate `audit_log_011.md`.
   - Commit changes to branch `TASK-011`.
