# [TICKET-007] Deep Recursive Anchoring Engine

**Status:** [x] DONE
**Assignee:** Gatekeeper (Merged)

## Goal Description
Refactor `tests/Deduplicate-CloudDrives.ps1` to integrate Deep Recursive Directory Traversal (Dynamic Anchoring). The script must recurse through all folders to identify actual audiobook directories (Leaf Folders containing audio files) before applying deduplication and asymmetrical size logic.

## Core Logic Requirements
- **Dynamic Anchoring:** Use `Get-ChildItem -Recurse -Directory`. Filter for folders that actually contain `.mp3, .m4b, .m4a, .flac`. These are the "Anchored Book Folders".
- **Master Scan:** Build the hash table strictly from Anchored Master Folders.
- **Target Scan:** Apply deduplication logic strictly against Anchored Target Folders, completely ignoring empty generic parent structures.
- **Empty Shell Rule:** Retain the logic that sweeps folders with zero audio files into `To Delete Audio Books`.
- **Asymmetrical Engine:** Retain the size check for matches (Master >= Target -> Target Deleted; Master < Target -> Target Superior).
- **Surgical Routing:** `Move-Item` only the specific anchored duplicate folder, leaving parent structures fully intact.
