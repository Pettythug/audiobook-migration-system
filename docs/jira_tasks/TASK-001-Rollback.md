# ENVELOPE: TASK-001

## 1. META
- `OBJECTIVE`: `EXECUTE(RESTORE_DRIVE_STATE)`
- `TARGET_DRIVE`: `G:\My Drive\pcloud`
- `SYSTEM_OVERRIDE`: `HALT_PLANNING_MODE`
- `PLANNING_MODE_DIRECTIVE`: `DENY(Implementation_Plans) REQUIRE(Immediate_Execution)`

## 2. INPUT_PARAMETERS
- `DATA_SOURCE`: `REQUIRE(READ: Sandbox_Drive\Manual_Review_Log.csv)`
- `FILTER_CRITERIA`: `[Reason == "Empty Shell" OR Reason == "Exact/Inferior Duplicate"]`

## 3. EXECUTION_LOGIC
- `TARGET_FILE`: `src/Rollback-CloudDrives.ps1`
- `ALGORITHM`: 
  1. `EVAL: Staging_Location(To Delete Audio Books OR To Delete Empty Folders)`
  2. `EVAL: TargetFolder(from CSV)`
  3. `EXECUTE: Move-Item -Path [Staging_Location] -Destination [TargetFolder]`

## 4. CONSTRAINTS
- `PHYSICAL_DESTRUCTION`: `DENY`
- `SAFETY_OVERRIDE`: `REQUIRE(-WhatIf)`
- `SRE_RULES`: `REQUIRE(Strict_Mode, Try/Catch, Write-Verbose, Write-Error)`

## 5. OUTPUT_ROUTING
1. `EXECUTE: WRITE_FILE(src/Rollback-CloudDrives.ps1)`
2. `EXECUTE: GIT_COMMIT`
3. `SCRIPT_EXECUTION`: `DENY`
4. `EXECUTE: WRITE_FILE(docs/jira_tasks/TASK-001-Rollback-Audit.md, content=[Rollback-CloudDrives.ps1 Source Code])`
5. `EXECUTE: HALT`
