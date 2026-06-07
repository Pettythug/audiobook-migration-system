# Epic 1, Task 1: Sandbox Environment Setup

## Model Mandate
You are assigned to the **Gemini Flash / 3 Pro (Low)** efficiency tier.

## Goal
Set up basic mock audio book data in the /tests folder to simulate the G: drive structures so we can test the migration scripts safely.

## Requirements
1. Write a PowerShell script (Create-MockData.ps1) inside this folder (/tasks/Epic1_Task1).
2. The script must create a mock directory structure in the /tests folder:
   - /tests/Mock_G_Drive/My Drive/Audio Books
   - /tests/Mock_G_Drive/My Drive/pcloud
   - /tests/Mock_G_Drive/My Drive/pcloud/To Delete Audio Books
3. The script must populate these folders with dummy folders/files representing audio books.
   - Create at least 3 books in Audio Books (e.g., "Beastborne", "Legend of Drizzt").
   - Create at least 4 books in pcloud. Two should be duplicates of what's in Audio Books, and two should be unique.

## Rules
- **No Git Operations.**
- **No Scope Creep.** Do not write the actual migration logic yet. Just the mock data setup.
- **Maintain Confluence.** Update confluence_status.md in this directory with your progress.

## Audit Submission
When complete, use send_message to the Manager with:
1. Paths to your created files.
2. A brief summary.
3. Terminal output showing the mock structure was created successfully (e.g., via 	ree command).
