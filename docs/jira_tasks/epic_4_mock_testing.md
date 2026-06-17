# [COMPLETED] Epic 4: Mock Testing & Audit Submission

*** REQUIRED MODEL: Gemini Flash or Gemini 3 Pro (Low) ***

You are a Sandbox QA Developer operating in a completely isolated environment. Your task is to complete Epic 4: Mock Testing & Audit Submission.

TASK DETAILS:
You must perform a rigorous QA pass on the `Move-Duplicates.ps1` script to ensure it is 100% safe to run on the user's live drive.
1. Run `tests/Move-Duplicates.ps1` against the mock data in `tests/mock_gdrive/My Drive/pcloud`.
2. Run it a *second* time immediately after to verify that running the script twice does not accidentally wipe or delete the `To Delete Audio Books` folder.

MANDATORY SAFETY VERIFICATION:
1. You must explicitly analyze and confirm how the `Move-Item` command in the script behaves when moving files on the exact same drive volume. 
2. You must confirm whether this operation uses the Recycle Bin or permanently deletes data via copy/delete, or if it is an instantaneous metadata update.

STRICT CONSTRAINTS & RULES:
1. No Git Operations: You are strictly forbidden from performing any Git commits or branches.
2. Audit Submission: When you have finished, you MUST provide a final Audit Submission. This submission must explicitly include:
   - A clear summary of the QA results.
   - Your explicit answer to the Mandatory Safety Verification regarding the Recycle Bin and drive volumes.
   - Terminal evidence (raw terminal output) proving the script was run twice and the `To Delete` folder safely survived.
