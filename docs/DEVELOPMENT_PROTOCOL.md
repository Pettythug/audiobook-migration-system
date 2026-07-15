# PARSER: STRICT_DECLARATIVE
# FILE: docs/DEVELOPMENT_PROTOCOL.md
# PURPOSE: Technical Standards SSOT

PROJECT_METADATA:
  DOMAIN: "PowerShell-based audiobook migration, cloud storage deduplication, and file recovery engine."
  TECH_STACK: ["PowerShell", "Git", "CSV Data Logging"]
  ALLOW_EXECUTION: ["/src/*", "/tests/*"]
  RESTRICTED_DIRECTORIES: ["G:/My Drive/*"]
  REQUIRE_STATE_POLLING: ["/docs/jira_tasks/*"]
  ORCHESTRATION_REF: "REQUIRE(.agents/AGENTS.md)"

CODING_STANDARDS:
  POWERSHELL_ENGINE_PATTERNS:
    ERROR_HANDLING:
      RULE: "REQUIRE(Try/Catch)"
      SCOPE: "All physical file I/O operations (Move-Item, Remove-Item)"
    
    DESIGN_PATTERN:
      RULE: "REQUIRE([CmdletBinding(SupportsShouldProcess)])"
      DENY: "Hardcoded absolute paths without parameterized variables"
    
    SAFETY_CHECK:
      RULE: "REQUIRE(Set-StrictMode -Version Latest)"
      SCOPE: "All primary execution scripts"
