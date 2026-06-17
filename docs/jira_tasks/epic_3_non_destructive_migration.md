# [COMPLETED] Epic 3: Non-Destructive Migration Script

*** REQUIRED MODEL: Gemini 3.1 Pro (High) ***

You are a Sandbox Developer operating in a completely isolated environment. Your task is to complete Epic 3: Non-Destructive Migration Script.

TASK DETAILS:
You must extend the `Compare-GDriveManifest.ps1` script (or create a new `Move-Duplicates.ps1` based on it). 
This script must:
1. Accept the same Manifest and Target Directory parameters.
2. Identify duplicates exactly as it did in Epic 2.
3. If a duplicate is found, the script must non-destructively MOVE that directory and all its contents to a staging folder named `To Delete Audio Books` located at the root of the Target Directory.
4. Ensure it creates the `To Delete Audio Books` directory if it does not exist.

STRICT CONSTRAINTS & RULES:
1. No Git Operations: You are strictly forbidden from performing any Git commits or branches.
2. Sandbox Testing Only: You must execute your script against the fake `tests/mock_gdrive/My Drive/pcloud` directory to prove it works.
3. Audit Submission: When you have finished, you MUST provide a final Audit Submission. This submission must explicitly include:
   - The complete, raw PowerShell source code in a markdown block.
   - A clear summary of the changes you made.
   - Terminal evidence (raw terminal output) proving the script ran, moved the fake duplicates to the staging folder, and left the New Titles alone.
