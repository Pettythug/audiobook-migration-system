# ENVELOPE: TASK-002

## 1. META
- `OBJECTIVE`: `EXECUTE(LIVE_DRY_RUN_DEDUPLICATION)`
- `TARGET_DRIVES`: `["G:\My Drive\pcloud\Drive I", "G:\My Drive\pcloud\Drive E"]`
- `ASSIGNED_ROLE`: `QA_Engineer`

## 2. INPUT_PARAMETERS
- `TARGET_FILE`: `src/Deduplicate-CloudDrives.ps1`
- `LOG_OUTPUT`: `Manual_Review_Log.csv`

## 3. EXECUTION_LOGIC
1. `EXECUTE`: PowerShell command to run `Deduplicate-CloudDrives.ps1`
2. `SAFETY_OVERRIDE`: **MUST INJECT `-WhatIf` FLAG INTO THE SCRIPT EXECUTION.**
3. `TARGET_PARAMETER`: Supply the TARGET_DRIVES array to the script's `-TargetDirectories` parameter.

## 4. CONSTRAINTS
- `PHYSICAL_DESTRUCTION`: `STRICTLY_DENY`
- `ENVIRONMENT_LOCK`: `ALLOW(Read)`
- `VALIDATION_MANDATE`: Verify the `-WhatIf` output correctly anchors the staging folders to the respective local sub-drives without cross-contamination.

## 5. OUTPUT_ROUTING
1. `OUTPUT`: Return the `-WhatIf` terminal output back to the Manager for final CTO code review and sign-off.
2. `EXECUTE`: `HALT`
