# Audiobook Migration System

This repository manages the deduplication, organization, and migration of audiobook libraries across multiple physical drives.

## Architecture & Task Tracking
- **Local Protocol:** See `docs/DEVELOPMENT_PROTOCOL.md` for strict role boundaries, safety constraints, and coding standards.
- **Jira Board:** Active tasks are tracked in `/docs/jira_tasks/`. The Manager autonomously maintains this board to guarantee State Recovery upon initialization.
  - **Current Active Task:** `docs/jira_tasks/TICKET-001-Content-Aware-Deduplication.md`
