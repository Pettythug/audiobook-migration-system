# [TICKET-002] Directory Mapping & Manifest Comparison

**Status:** IN PROGRESS
**Assignee:** Sandbox Developer

## Goal Description
Build `tests/Compare-ManifestToPcloud.ps1`. This script must compare the local cleaned audiobook directories against the existing cloud manifests to identify which audiobooks are already backed up and which are missing from the cloud.

## Proposed Changes
### `[NEW]` `tests/Compare-ManifestToPcloud.ps1`
- **Manifest Ingestion:** Read the cloud manifests.
- **Local Scan:** Scan the local target directory for remaining (deduplicated) audiobooks.
- **Comparison Engine:** Match local folders to manifest entries based on "Clean Titles" (stripping the `[ID]` tags).
- **Reporting:** Export a report (`migration_report.csv`) categorizing each local audiobook as `[SYNCED]` or `[PENDING UPLOAD]`.
- **Defensive Coding:** Enforce `Try/Catch` blocks and `-LiteralPath` strictly.

## Verification Plan
1. The Gatekeeper will audit the code against the new `ALLOW/DENY` protocol syntax.
2. The Developer will write `tests/test_manifest.ps1` to generate mock data and prove the comparison logic works before merging.
