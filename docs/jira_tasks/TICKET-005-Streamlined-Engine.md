# [TICKET-005] Streamlined Single-Pass Engine

**Status:** IN PROGRESS
**Assignee:** Sandbox Developer

## Goal Description
Build `tests/Deduplicate-CloudDrives.ps1`. The script must execute a streamlined, live in-memory deduplication across 4 physical target drives. It will identify duplicates based on Clean Title matching, resolve asymmetrical conflicts based on total byte size, and identify "Empty Shells" containing zero audio files.

## Core Logic Requirements
- **Master Scan:** Build a hash table of all "Clean Titles" in the Master directory.
- **Target Iteration:** Loop through the Target Directories array.
- **Empty Shell Routing:** If a folder has no `.mp3`, `.m4b`, `.m4a`, or `.flac` files, route it to `To Delete Audio Books`.
- **Asymmetrical Engine:** If Clean Titles match, calculate total byte size of both folders.
  - If Master >= Target: Move Target to `To Delete Audio Books`.
  - If Master < Target: Spare Target. Write to `Manual_Review_Log.csv` as `Target Superior`.
