# [TICKET-004] Multi-Drive Cloud Deduplication

**Status:** IN PROGRESS
**Assignee:** Sandbox Developer

## Goal Description
Build `tests/Deduplicate-CloudDrives.ps1`. The script must compare a Master source directory against an array of 4 pCloud directories. For any audiobook found in the pCloud directories that already exists in the Master directory, the script will non-destructively move the pCloud duplicate into a local `To Delete Audio Books` staging folder located inside that specific pCloud directory.

## Proposed Changes
### `[NEW]` `tests/Deduplicate-CloudDrives.ps1`
- **Master Scan:** Build a hash table of all "Clean Titles" existing in the Master directory (stripping `[ID]` tags).
- **Target Array Iteration:** Loop through 4 target folders: `pcloud\Audio Books`, `pcloud\Drive G`, `pcloud\Drive I`, `pcloud\Drive E`.
- **Duplicate Detection:** For every audiobook folder inside a target, check if its "Clean Title" exists in the Master hash table.
- **Non-Destructive Routing:** If a duplicate is found, move it to `[Target Folder]\To Delete Audio Books`.
- **Defensive Coding:** `Try/Catch` blocks for file I/O. `-LiteralPath` strictly enforced.

## Verification Plan
1. The Gatekeeper will audit the code against `GLOBAL_RULES.md`.
2. The Developer will write `tests/test_cloud_dedupe.ps1` to mathematically prove duplicates route perfectly in a mock environment before merging.
