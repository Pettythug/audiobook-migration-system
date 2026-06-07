# Manager's Audit Checklist

Use this strict pass/fail rubric to evaluate every developer submission. Do not approve code to merge to `main` unless every box is checked.

- [ ] **Scope Verification**: Does the code exactly match the Jira task requirements without any unauthorized scope creep or 'helpful' additions?
- [ ] **No Git Operations**: Did the developer abstain completely from running Git commands?
- [ ] **Style Guide Compliance**: 
  - [ ] Functions use standard `Verb-Noun` naming.
  - [ ] Strict `Try-Catch` error handling is present.
  - [ ] Clean and standard console logging is used.
- [ ] **Staging Folder Integrity**: Does the script strictly use `Move-Item` and unequivocally avoid any destructive `Remove-Item` logic against the staging folder?
- [ ] **Test Evidence**: Did the developer provide terminal evidence showing mock tests passing 100%?
- [ ] **Confluence Updated**: Is the `confluence_status.md` properly updated inside the developer's `/tasks` folder?

**Manager Action on Pass**:
Merge code into `src` or `tests`, move task folder to `archive`, commit locally to a feature branch (`feature/EpicX_TaskY`), and request User review to push to GitHub.
