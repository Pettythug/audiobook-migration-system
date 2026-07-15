# Local Project Protocol & Architecture

This document serves as the project-specific source of truth for Technical Standards and Tech Stack constraints. 
For Orchestration, Delegation sequences, and Agent Constraints, refer strictly to `.agents/AGENTS.md`.

---

## 1. Project Metadata & Topology
- `DOMAIN`: "PowerShell-based audiobook migration, cloud storage deduplication, and file recovery engine."
- `TECH_STACK`: `["PowerShell", "Git", "CSV Data Logging"]`
- `ALLOW_EXECUTION`: `["/src/*", "/tests/*"]`
- `RESTRICTED_DIRECTORIES`: `["G:/My Drive/*"]` (Unless explicitly authorized by a strict Jira execution ticket)
- `REQUIRE_STATE_POLLING`: `["/docs/jira_tasks/*"]`

---

## 2. Coding & Refactoring Standards

### PowerShell Engine Patterns
- `ERROR_HANDLING`: `REQUIRE(Try/Catch) SCOPE(All physical file I/O operations such as Move-Item, Remove-Item)`
- `DESIGN_PATTERN`: `REQUIRE([CmdletBinding(SupportsShouldProcess)]) DENY(Hardcoded absolute paths without parameterized variables)`
- `SAFETY_CHECK`: `REQUIRE(Set-StrictMode -Version Latest) SCOPE(All primary execution scripts)`
