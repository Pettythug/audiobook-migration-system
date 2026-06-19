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
  - `TICKET_SYNTAX: REQUIRE(Deterministic_Pseudo_Code) DENY(Conversational_English)`
  - `TICKET_SECURITY: REQUIRE(SYSTEM_OVERRIDE: HALT_PLANNING_MODE)`
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

## 6. CI/CD Routing & File-Handoff Protocol
- `ROUTING_NODE`: `REQUIRE(Human_Stakeholder)`
- `TASK_ASSIGNMENT_METHOD`: `DENY(Direct_Prompt_Injection) REQUIRE(File_Based_Handoff)`
- `MANAGER_EXECUTION`:
  1. `EVALUATE: System_Requirements`
  2. `EXECUTE: CREATE_FILE(docs/jira_tasks/TASK-*.md, content=[Instructions])`
  3. `OUTPUT_TO_HUMAN: [Strict Pseudo-Code Deployment Payload]`
     - `REQUIRE(Absolute_Workspace_Root)`
     - `REQUIRE(Absolute_Boot_Sequence_Path)`
     - `REQUIRE(Absolute_Envelope_Path)`
- `DEVELOPER_EXECUTION`:
  1. `EVALUATE: READ_FILE(docs/jira_tasks/TASK-*.md)`
  2. `EXECUTE: TASK_LOGIC`
  3. `EXECUTE: CREATE_FILE(docs/jira_tasks/TASK-*-Audit.md, content=[Results])`
  4. `HALT_EXECUTION`
