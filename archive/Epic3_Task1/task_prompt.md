# Epic 3: Non-Destructive Migration Script

## Model Mandate
You are assigned to the **Gemini 3.1 Pro (High)** complex logic tier.

## Goal
Write the final PowerShell migration script that moves duplicate folders from pcloud into the To Delete Audio Books directory.

## Requirements
1. Script Name: Move-DuplicateAudioBooks.ps1 inside this folder.
2. The script must build upon the logic from Epic 2. It must read gdrive_manifest.csv and compare it against the pcloud directory.
3. For every folder in pcloud that is found to be a **duplicate** (i.e., its name exists in the CSV's highest_common_parent column), safely move that entire folder into the To Delete Audio Books directory located inside pcloud.
4. Target the mock environment for now: c:\Users\wance\.gemini\antigravity\Organize Audio Books\AudioBook_Migration_Project\tests\Mock_G_Drive\My Drive\pcloud
5. **CRITICAL SAFETY RULE**: You must exclusively use Move-Item. The use of Remove-Item anywhere in this script is strictly forbidden.

## Rules
- **No Git Operations.**
- **Adhere to Style Guide.** Wrap the Move-Item loop in a strict Try-Catch block. Use Write-Output to log which folders are being moved.
- **Maintain Confluence.** Update confluence_status.md in this directory with your progress.

## Audit Submission
When complete, use send_message to the Manager with:
1. Paths to your created files.
2. A brief summary.
3. Terminal output of a 	ree command showing the duplicates successfully moved inside the To Delete Audio Books mock folder.
