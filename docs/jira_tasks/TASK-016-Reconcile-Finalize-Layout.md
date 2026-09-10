# TASK-016: Final 04_Media Residual Reconciliation, Layout Finalization & Extras Audit

## Ticket Details
- **Issue Key:** `TASK-016`
- **Epic:** `Batch 1 — 04_Media Reorganization & Reconciliation`
- **Assigned Role:** Sandbox_Developer / Manager
- **Status:** **IN PROGRESS**
- **Creation Date:** 2026-09-10

---

## 1. Objective & Scope
1. **Rescue Stranded Media**: Relocate lingering audio assets in legacy folders (`Drive E` and `Drive I`) into `_Uncataloged`.
2. **Sweep Defunct Drive Shells**: Discard thumbnail/search caches into `To Delete Empty Folders` and sweep empty directories (`Audiobooks` shell, `Drive E`, `Drive I`, `Drive G`).
3. **Rename Master Directory**: Rename `Organized Audiobooks` to `Audiobooks` to match `P:_Media\Audiobooks` 1-to-1.
4. **Master Catalog Generation**: Place the master spreadsheet catalog directly inside `Audiobooks\Media_Master_Catalog.csv`.
5. **Extras Forensic Audit**: Analyze every title in `_Uncataloged` against `audiobookshelf_library.json` to categorize duplicate clusters, fuzzy matches, and genuine standalone extras.

---

## 2. Governance Constraints
- `STRICTLY_DENY(Access: "P:\*")`
- `STRICTLY_DENY(Remove-Item)`: Zero permanent deletions.
- All non-audio caches discarded to holding cells on `G:\`.
