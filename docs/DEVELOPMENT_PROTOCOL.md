# Audiobook Migration System - Local Development Protocol

## 1. Project_Metadata
- `DOMAIN`: "Audiobook storage cleanup, deduplication, and file migration across external drives."
- `TECH_STACK`: `["PowerShell"]`

## 2. Machine_Topology
- `ALLOW_EXECUTION`: `["/src/*", "/tests/*"]`
- `REQUIRE_STATE_POLLING`: `["/docs/jira_tasks/*"]`
- `RESTRICTED_DIRECTORIES`: `["/archive/*"]`

## 3. Role Execution & Isolation

### Role: Sandbox_Developer
- `WORKSPACE_ACCESS`: `ALLOW(["/src/*", "/tests/*"])`
- `INFRASTRUCTURE_ACCESS`: `DENY(["/docs/*", "README.md", "GLOBAL_RULES.md"])`
- `GIT_PERMISSIONS`: `ALLOW([checkout -b, add ., commit -m]) DENY([push *])`
- `EXECUTION_SEQUENCE`: 
  1. `AWAIT: STATE_CHANGE(docs/jira_tasks/TASK-*.md)`
  2. `EXECUTE: ASSIGNED_TICKET_LOGIC`
  3. `EXECUTE: GIT_COMMIT`
  4. `HALT_EXECUTION`
  5. `OUTPUT: AUDIT_REPORT`

### Role: Manager_Gatekeeper
- `WORKSPACE_ACCESS`: `ALLOW(["/*"])`
- `GIT_PERMISSIONS`: `ALLOW(["ALL"])`
- `WORK_MANAGEMENT`:
  - `TRACK_EPICS: REQUIRE(docs/jira_board.md)`
  - `ASSIGN_TASKS: REQUIRE(docs/jira_tasks/TASK-*.md)`
- `EXECUTION_SEQUENCE`:
  1. `EVALUATE: AUDIT_REPORT`
  2. `IF (Audit == PASS): AWAIT_USER_MERGE_APPROVAL`
  3. `IF (Audit == FAIL): ASSIGN_TICKET(docs/jira_tasks/TASK-*.md)`

## 4. Execution_Constraints
- `PRE_FLIGHT_CHECK_REQUIRED`: `true`
- `ON_AMBIGUITY`: `HALT_AND_PROMPT_USER`

## 5. Coding_Standards (Universal SRE + Local Patterns)
- `ERROR_HANDLING`: `REQUIRE(Try/Catch) SCOPE(File I/O) ACTION(Throw Terminating Errors)`
- `DRY_RUN_SAFETY`: `REQUIRE(-WhatIf) SCOPE(Destructive Functions)`
- `LANGUAGE_PRAGMA`: `REQUIRE(Set-StrictMode -Version Latest) LOCATION(Script Header)`
- `OUTPUT_STREAMS`: `DENY(Write-Host) REQUIRE(Write-Verbose, Write-Error)`
- `VARIABLE_NAMING`: `REQUIRE(Global: PascalCase, Local: camelCase)`
- `DESTRUCTIVE_ACTIONS`: `DENY(Remove-Item) REQUIRE(Move-Item)`
