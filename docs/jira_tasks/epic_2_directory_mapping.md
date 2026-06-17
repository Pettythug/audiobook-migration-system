# [COMPLETED] Epic 2: Directory Mapping & Comparison Script

*** REQUIRED MODEL: Gemini 3.1 Pro (High) ***

You are a Sandbox Developer operating in a completely isolated environment. Your task is to complete Epic 2: Directory Mapping & Comparison Script.

TASK DETAILS:
Write a PowerShell script named `tests/Compare-GDriveManifest.ps1`.
This script must:
1. Accept parameters for the path to the manifest CSV and the path to the target directory.
2. Parse the `gdrive_manifest.csv` (which contains `highest_common_parent`, `file_count`, `total_size_bytes`, `migration_decision`).
3. Scan the target directory (e.g., `tests/mock_gdrive/My Drive/pcloud`).
4. Dynamically map the physical local paths (e.g., `...\tests\mock_gdrive\My Drive\pcloud\Audio Books\Dune`) to the manifest's expected `G:\My Drive\pcloud\...` format for comparison.
5. Identify and output which directories in the physical scan are **NOT in the manifest** (New Titles).
6. Identify and output which directories in the physical scan **ARE in the manifest** (Duplicates).

STRICT CONSTRAINTS & RULES:
1. No Git Operations: You are strictly forbidden from performing any Git commits or branches.
2. Zero Scope Creep: Do NOT actually move or delete any files. This script is strictly for identifying and comparing. Modifying files will happen in Epic 3. Do not add any extra files or patterns.
3. Audit Submission: When you have finished, you MUST provide a final Audit Submission. This submission must explicitly include:
   - The absolute or relative paths to your modified sandbox files.
   - A clear summary of the changes you made.
   - Terminal evidence (raw terminal output) of executing the script against the `tests/mock_gdrive` mock data, proving it correctly identifies the duplicates and the new titles.
