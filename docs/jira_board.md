# AudioBook Migration - Jira Board

## Epic 1: Sandbox Environment Setup
- **Assignee Model**: Gemini Flash or Gemini 3 Pro (Low)
- **Status**: TO DO
- **Task 1.1**: Set up basic mock audio book data in the /tests folder to simulate the G: drive structures.

## Epic 2: Directory Mapping & Comparison Script
- **Assignee Model**: Gemini 3.1 Pro (High)
- **Status**: TO DO
- **Task 2.1**: Write a PowerShell script that parses gdrive_manifest.csv.
- **Task 2.2**: Script must scan the G:\My Drive\pcloud equivalent (mocked initially) and find titles not in the manifest.

## Epic 3: Non-Destructive Migration Script
- **Assignee Model**: Gemini 3.1 Pro (High)
- **Status**: TO DO
- **Task 3.1**: Script must identify duplicate titles existing in both locations.
- **Task 3.2**: Script must non-destructively MOVE duplicates to G:\My Drive\pcloud\To Delete Audio Books.

## Epic 4: Mock Testing & Audit Submission
- **Assignee Model**: Gemini Flash or Gemini 3 Pro (Low)
- **Status**: TO DO
- **Task 4.1**: Execute tests against the mock data in /tests.
- **Task 4.2**: Verify that the staging folder To Delete Audio Books is never deleted or wiped.
- **Task 4.3**: Prepare audit submission with paths, summary, and terminal output of passing tests.
