# PLAN-003: Deduplication Engine WhatIf Refactor

Move `Deduplicate-CloudDrives.ps1` to the `src/` directory and wrap all physical file operations in `$PSCmdlet.ShouldProcess()` so it supports the `-WhatIf` flag perfectly. Update tests and references.

## Proposed Changes

### Core Scripts

#### [MODIFY] [Deduplicate-CloudDrives.ps1](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/src/Deduplicate-CloudDrives.ps1)
- Add `[CmdletBinding(SupportsShouldProcess)]` to the top of the param block.
- Wrap `New-Item` calls in `if ($PSCmdlet.ShouldProcess($ToDeleteDir, "Create Directory")) { ... }` and `if ($PSCmdlet.ShouldProcess($ToDeleteEmptyDir, "Create Directory")) { ... }`.
- Wrap empty shell folder `Move-Item` and its CSV log append in `if ($PSCmdlet.ShouldProcess($Shell.FullName, "Move to $Dest")) { ... }`.
- Wrap duplicate book folder `Move-Item` and its CSV log append in `if ($PSCmdlet.ShouldProcess($Anchored.FullName, "Move to $Dest")) { ... }`.

### Tests

#### [MODIFY] [test_cloud_dedupe.ps1](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/tests/test_cloud_dedupe.ps1)
- Update script reference from `Deduplicate-CloudDrives.ps1` under `$PSScriptRoot` to `../src/Deduplicate-CloudDrives.ps1`.

#### [MODIFY] [test_singlepass.ps1](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/tests/test_singlepass.ps1)
- Update script reference from `Deduplicate-CloudDrives.ps1` under `$PSScriptRoot` to `../src/Deduplicate-CloudDrives.ps1`.

#### [MODIFY] [test_rollback.ps1](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/tests/test_rollback.ps1)
- Update script reference path from `tests\Deduplicate-CloudDrives.ps1` to `src\Deduplicate-CloudDrives.ps1`.

### Cleanup

#### [DELETE] [Deduplicate-CloudDrives.ps1](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/tests/Deduplicate-CloudDrives.ps1)
- Remove the original script location.

### Audit & Log

#### [NEW] [audit_log_003.md](file:///C:/Users/wance/Documents/Git/audiobook-migration-system/audit_log_003.md)
- Create `/audit_log_003.md` detailing the changes made for TASK-003.

---

## Verification Plan

### Automated Tests
1. Run updated cloud deduplication test:
   `powershell -File C:\Users\wance\Documents\Git\audiobook-migration-system\tests\test_cloud_dedupe.ps1`
2. Run updated singlepass deduplication test:
   `powershell -File C:\Users\wance\Documents\Git\audiobook-migration-system\tests\test_singlepass.ps1`
3. Run updated rollback test:
   `powershell -File C:\Users\wance\Documents\Git\audiobook-migration-system\tests\test_rollback.ps1`

### Manual Verification
- Execute a dry-run against the synthetic data in `tests/MockTarget` using the `-WhatIf` flag to prove no modifications occur and no errors are thrown:
  `powershell -Command "& C:\Users\wance\Documents\Git\audiobook-migration-system\src\Deduplicate-CloudDrives.ps1 -MasterDirectory C:\Users\wance\Documents\Git\audiobook-migration-system\tests\Mock_G_Drive -TargetDirectories @('C:\Users\wance\Documents\Git\audiobook-migration-system\tests\MockTarget') -WhatIf"`
