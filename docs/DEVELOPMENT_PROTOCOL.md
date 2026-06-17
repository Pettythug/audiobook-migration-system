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
  - `DENY`: `git checkout main`
  - `DENY`: `git merge *`
  - `DENY`: `git push *`
- **Execution_Directive**: 
  1. Await explicit Ticket Assignment from Manager.
  2. Instantiate the exact branch name provided by Manager.
  3. Commit code to isolated branch.
  4. HALT and submit Audit Report to Manager.

### Role: Manager_Gatekeeper
- **Workspace_Access**: `ALLOW: ["/*"]`
- **Git_Permissions**: `ALLOW: ["ALL"]`
- **Execution_Directive**:
  1. Generate strict branch names for Developer assignment.
  2. Audit Developer's isolated branch against this protocol.
  3. Execute physical Git merges into `main` exclusively upon User approval.

## 4. Execution_Constraints
- `PRE_FLIGHT_CHECK_REQUIRED`: `true` (Must review `/docs/jira_tasks` before structural changes).
- `ON_AMBIGUITY`: `HALT_AND_PROMPT_USER` (Never infer intent).

## 5. Coding_Standards
- `COMMIT_FORMAT`: `"Conventional Commits" (e.g., feat:, fix:, docs:)`
- `STANDARD_1`: `MUST_USE: Try/Catch blocks for file I/O.`
- `STANDARD_2`: `DENY: Remove-Item. MUST_USE: Move-Item for deduplication routing.`
