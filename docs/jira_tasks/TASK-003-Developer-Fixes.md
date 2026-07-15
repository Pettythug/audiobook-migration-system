# TASK-003: Deduplication Engine WhatIf Refactor

> **For Human Readers:** The QA Agent failed the `-WhatIf` dry-run on `tests/Deduplicate-CloudDrives.ps1` because the script does not support ShouldProcess (WhatIf) and was not located in the `src/` directory. The Sandbox Developer must relocate the script and inject the mandatory Safety Checks so it can run non-destructively.

```text
<TASK_EXECUTION_PROTOCOL>
  <GATEKEEPER>
    - TASK_CLASS: SINGLE_FILE_FEATURE
    - REQUIRED_MODEL_TIER: MEDIUM_TIER
  </GATEKEEPER>
  <ROLE_DEFINITION>
    - ASSIGNED_ROLE: Sandbox_Developer
    - SYSTEM_OVERRIDE: STRICTLY_DENY(Read/Write: ["G:/My Drive/*"])
  </ROLE_DEFINITION>
  <ENVIRONMENT_SETUP>
    - TARGET_BRANCH: `TASK-003`
  </ENVIRONMENT_SETUP>
  <OBJECTIVE>
    Move Deduplicate-CloudDrives.ps1 to the src directory and wrap all physical file operations in $PSCmdlet.ShouldProcess() so it supports the -WhatIf flag perfectly.
  </OBJECTIVE>
  <RESOURCES>
    - tests/Deduplicate-CloudDrives.ps1
  </RESOURCES>
  <SEQUENCE>
    1. READ `tests/Deduplicate-CloudDrives.ps1`.
    2. MODIFY:
       - Move the file to `src/Deduplicate-CloudDrives.ps1`.
       - Add `[CmdletBinding(SupportsShouldProcess)]` to the top of the param block.
       - Wrap `New-Item` calls (lines 55, 58) in `if ($PSCmdlet.ShouldProcess($ToDeleteDir, "Create Directory")) { ... }`.
       - Wrap `Move-Item` calls for Empty Shells (line 89) and Inferior Duplicates (line 111) in `if ($PSCmdlet.ShouldProcess($Shell.FullName, "Move to $Dest")) { ... }`.
       - Remove `tests/Deduplicate-CloudDrives.ps1`.
    3. AUDIT: Generate `/audit_log_003.md` in the workspace root detailing changes.
    4. VERIFY: Execute a mock test run against synthetic data in `tests/MockTarget` using the `-WhatIf` flag to prove it does not throw errors.
  </SEQUENCE>
</TASK_EXECUTION_PROTOCOL>
```
