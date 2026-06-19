# Audiobook Migration System - Local Development Protocol

## 1. Project_Metadata
- `Domain`: "Audiobook storage cleanup, deduplication, and file migration across external drives."
- `Tech_Stack`: `["PowerShell"]`

## 2. Machine_Topology
- `ALLOW_EXECUTION`: `["/src/*", "/tests/*"]`
- `REQUIRE_STATE_POLLING`: `["/docs/jira_tasks/*"]`
- `RESTRICTED_DIRECTORIES`: `["/archive/*"]`

## 3. Role Execution & Isolation

### Role: Sandbox_Developer
- **Workspace_Access**: `ALLOW: ["/src/*", "/tests/*"]`
- **Infrastructure_Access**: `DENY: ["/docs/*", "README.md", "GLOBAL_RULES.md"]`
- **Git_Permissions**:
  - `ALLOW`: `git checkout -b <manager_assigned_branch>`
  - `ALLOW`: `git add .`
  - `ALLOW`: `git commit -m "<msg>"`
  - `DENY`: `git push *`
- `EXECUTION_SEQUENCE`: 
  1. `AWAIT: STATE_CHANGE(docs/jira_tasks/TASK-*.md)`
  2. `EXECUTE: ASSIGNED_TICKET_LOGIC`
  3. `EXECUTE: GIT_COMMIT`
  4. `HALT_EXECUTION`
  5. `OUTPUT: AUDIT_REPORT`

### Role: Manager_Gatekeeper
- **Workspace_Access**: `ALLOW: ["/*"]`
- **Git_Permissions**: `ALLOW: ["ALL"]`
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
- `ERROR_HANDLING`: `MUST_USE: Try/Catch blocks for all File I/O. Terminating errors must bubble up.`
- `DRY_RUN_SAFETY`: `REQUIRE: -WhatIf switch support built into all destructive functions.`
- `LANGUAGE_PRAGMA`: `REQUIRE: Set-StrictMode -Version Latest` at the top of all scripts to catch undeclared variables.
- `OUTPUT_STREAMS`: `DENY: Write-Host.` `REQUIRE: Write-Verbose` for state tracking and `Write-Error` for failures.
- `VARIABLE_NAMING`: `REQUIRE: PascalCase for Globals, camelCase for Locals.`
- `DESTRUCTIVE_ACTIONS`: `DENY: Remove-Item. MUST_USE: Move-Item.`
