# TASK-006: Consolidate Unique Audiobooks

> **For Human Readers:** This task creates `src/Consolidate-AudioBooks.ps1`. The script sweeps `Drive I`, `Drive E`, and `Drive G` for any remaining audiobook folders and performs a direct, same-volume Move to `Organized Audiobooks`.

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: SINGLE_FILE_FEATURE
    - REQUIRED_MODEL_TIER: MEDIUM_TIER
  </GATEKEEPER>
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: Sandbox_Developer
    - SYSTEM_OVERRIDE: TEMPORARY_ALLOW(Write: ["/src/Consolidate-AudioBooks.ps1", "/tests/test_consolidate.ps1"])
  </ROLE_DEFINITION>
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-006`
  </ENVIRONMENT_SETUP>
  <OBJECTIVE>
    Create `src/Consolidate-AudioBooks.ps1` to move all remaining unique audiobook folders from specific target drives into a final Organized Audiobooks destination.
  </OBJECTIVE>
  <RESOURCES>
    - src/Consolidate-AudioBooks.ps1 (To be created)
    - tests/test_consolidate.ps1 (To be created)
  </RESOURCES>
  <SEQUENCE>
    1. PLAN: Write your execution plan to `docs/jira_tasks/plans/PLAN-006.md` and commit it.
    2. CREATE `src/Consolidate-AudioBooks.ps1`:
       - Must accept `-SourceDirectories` (Array) and `-DestinationDirectory` (String).
       - Must implement `[CmdletBinding(SupportsShouldProcess)]`.
       - For each directory in `SourceDirectories`, find all audiobook folders (folders containing `.mp3`, `.m4b`, etc., or just top-level folders). Actually, since the drives have been deduplicated and empty shells removed, just move the top-level folders within the SourceDirectories to the DestinationDirectory.
       - CRITICAL GOOGLE DRIVE REQUIREMENT: The move MUST use a standard `Move-Item` on the same volume (e.g. from `G:\` to `G:\`). Do not use any logic that performs a Copy followed by a Remove, as this fills up the Google Drive Trash and duplicates cloud storage. Use strict `Move-Item` which triggers a native `Rename` OS call.
       - Wrap all `Move-Item` and `New-Item` calls in `$PSCmdlet.ShouldProcess`.
    3. CREATE `tests/test_consolidate.ps1`:
       - Write a mock test suite that creates mock source drives, runs the script, and asserts the folders were moved to the destination.
    4. VERIFY: Run `tests/test_consolidate.ps1` and ensure it passes.
    5. AUDIT: Generate `/audit_log_006.md` detailing the test results.
  </SEQUENCE>
</TASK_EXECUTION_PROTOCOL>
```
