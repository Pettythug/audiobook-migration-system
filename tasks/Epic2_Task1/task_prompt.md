# Epic 2: Directory Mapping & Comparison Script

## Model Mandate
You are assigned to the **Gemini 3.1 Pro (High)** complex logic tier.

## Goal
Write a PowerShell script that parses the gdrive_manifest.csv and compares it against the mock pcloud directory to find Audio Books that exist in pcloud but are NOT in the manifest.

## Requirements
1. Script Name: Compare-ManifestToPcloud.ps1 inside this folder.
2. The script must read gdrive_manifest.csv (located at c:\Users\wance\.gemini\antigravity\Organize Audio Books\gdrive_manifest.csv) using Import-Csv.
3. The script must scan the mock pcloud directory (located at c:\Users\wance\.gemini\antigravity\Organize Audio Books\AudioBook_Migration_Project\tests\Mock_G_Drive\My Drive\pcloud).
4. Compare the child folder names in pcloud against the highest_common_parent column in the CSV.
5. Output two lists to the console:
   - "Missing from Audio Books (Unique to pcloud):" -> list the folder names.
   - "Duplicates Found:" -> list the folder names.
6. **No Destructive/Move Actions Yet**. This script only reports. Epic 3 handles the moving.

## Rules
- **No Git Operations.**
- **Adhere to Style Guide.** Use standard Verb-Noun naming, Try-Catch blocks, and clean logging.
- **Maintain Confluence.** Update confluence_status.md in this directory with your progress.

## Audit Submission
When complete, use send_message to the Manager with:
1. Paths to your created files.
2. A brief summary.
3. Terminal output demonstrating the script correctly identifying the missing vs duplicate mock data.
