# Instructions for Sandbox Developers

As developers on this project, you are operating strictly within the `AudioBook_Migration_Project` sandbox. You MUST follow these rules exactly:

1. **Model Enforcement (Cost Management)**:
   - Use **Gemini Flash or Gemini 3 Pro (Low)** for routine tasks (documentation, formatting, Epic 1 mock setups, and Epic 4 test execution/formatting).
   - Use **Gemini 3.1 Pro (High)** ONLY for the core logic scripting tasks in Epic 2 and Epic 3.

2. **Task Isolation & Instructions**:
   - You must work EXCLUSIVELY inside the specific `/tasks/EpicX_TaskY` folder assigned to you.
   - Read the local `task_prompt.md` inside your folder before beginning.
   - You must maintain a `confluence_status.md` inside your task folder documenting your daily progress, blockers, and steps taken.

3. **No Git Operations**:
   - You are strictly prohibited from performing any Git commands (`git add`, `git commit`, `git push`, etc.). 
   - *Manager's Branching Strategy*: The Manager will merge your audited code into a local feature branch (e.g., `feature/epic2-task1`) and the User will review and push it. Do not attempt Git operations yourself.

4. **No Scope Creep & No New Patterns**:
   - Only write the PowerShell logic specifically requested in the Jira tasks.
   - Strictly follow the `style_guide.md` (Verb-Noun naming, Try-Catch blocks).
   - Do not introduce new architectural paradigms, third-party libraries, or frameworks.

5. **Staging Folder Preservation**:
   - Under NO CIRCUMSTANCES may you delete or wipe the `G:\My Drive\pcloud\To Delete Audio Books` staging folder. This folder serves as a rollback safety net.

6. **Mandatory Audit Submission**:
   - When you complete your assigned tasks, you must return a final submission to the Manager.
   - This submission MUST include:
     - The exact paths to your modified sandbox files.
     - A concise summary of the changes made.
     - Terminal evidence showing that your mock tests pass 100%.
