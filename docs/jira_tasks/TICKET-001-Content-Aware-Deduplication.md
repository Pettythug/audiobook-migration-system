# [TICKET-001] Content-Aware Deduplication Engine

**Status:** [x] DONE
**Assignee:** Gatekeeper (Merged)

## Goal Description
Rewrite `tests/Move-Duplicates.ps1` to perform intelligent, content-aware deduplication instead of blindly following a manifest. The script will group duplicate audiobooks using Regex matching, analyze the file counts, audio file presence, and sizes of the duplicates, and safely route asymmetrical matches to a review log while silently trashing exact matches and empty shells.

## Proposed Changes

### `[MODIFY]` `tests/Move-Duplicates.ps1` (or create new `Deduplicate-Audiobooks.ps1`)
- **Regex Grouping Engine:** The script will scan all target directories, extract the leaf folder name, strip any `[ID]` tags (e.g. `[B01...]`), and group the physical folders by this "Clean Title". Note: Account for the 'Chaos' directory structure by dynamically anchoring to the audio file parent directory.
- **Content Analysis:** For any group containing 2 or more duplicate folders, the script will dive inside using **unbounded deep recursion** (`Get-ChildItem -Recurse`). It will search infinitely deep into every nested subfolder to guarantee no hidden audio files are missed, calculating:
  1. **Total File Count**
  2. **Total Size (MB)**
  3. **Audio File Count** (Checking for `.mp3`, `.m4a`, `.m4b`, `.flac`, `.wav`, `.wma`, `.ogg`)
- **Sorting Logic:** The script will sort the group by size. The largest/most populated folder will be designated the "Keeper." The remaining folders will be designated "Candidates for Deletion."
- **The Execution & Logging Engine:**
  - **Apples-to-Apples:** If a Candidate has the *exact same* total file count and size as the Keeper, it will be moved to `To Delete Audio Books` silently. (No log needed).
  - **The Empty Shell Rule:** If the Keeper has audio files, but the Candidate has ZERO audio files (even if it has subfolders, JPEGs, or text files), the Candidate is not an audiobook. It will be moved to `To Delete Audio Books` silently. (No log needed).
  - **Asymmetrical (Apples-to-Oranges):** If both the Keeper and the Candidate contain audio files, but they differ in count or size, the Candidate will be moved to `To Delete Audio Books` AND logged to `Manual_Review_Log.csv`. This log will display the Keeper's stats next to the Candidate's stats for manual human review.

## Verification Plan
1. Ensure the new code does not violate any of the 12 Global Rules or the Local Development Protocol.
2. I will write a mock test script (`test_run.ps1`) that generates fake folders simulating:
   - "Apples-to-Apples" (Exact matches)
   - "Empty Shells" (Folders with no audio files)
   - "Asymmetrical" (Both have audio, but different sizes)
3. I will execute the new `Deduplicate-Audiobooks.ps1` on the mock folders to guarantee it silently stages the first two, and accurately logs the third before we touch your live data.
