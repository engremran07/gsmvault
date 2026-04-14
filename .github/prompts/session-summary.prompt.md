---
agent: 'agent'
description: 'Generate end-of-session summary: files changed, features added, bugs fixed, tests written, decisions made, remaining work.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# Session Summary

Generate a comprehensive end-of-session summary suitable for appending to `SESSION_LOG.md`.

## Step 1 — Gather Changes

1. Run `git status` to see all modified, added, and deleted files.
2. Run `git diff --stat` to get a summary of changes by file.
3. Run `git log --oneline -20` to see recent commits this session.
4. If there are uncommitted changes, note them separately.

## Step 2 — Categorize Changes

Group all changes into categories:

### Files Created
List every new file with its purpose:
- `apps/<app>/newfile.py` — [brief purpose]

### Files Modified
List every modified file with what changed:
- `apps/<app>/models.py` — Added `NewModel` with X fields

### Files Deleted
List any removed files with reason:
- `apps/<app>/old_file.py` — Consolidated into existing module

## Step 3 — Summarize Work Done

### Features Added
- [Feature name]: [one-line description of what was implemented and where]

### Bugs Fixed
- [Bug description]: [root cause and fix applied, file:line]

### Tests Written
- [Test file]: [number of test cases, what they cover]

### Refactoring Done
- [What was refactored]: [why and how]

### Configuration Changes
- [Settings, requirements, config changes]

## Step 4 — Document Decisions

List any architectural or design decisions made during the session:

- **Decision**: [What was decided]
  - **Rationale**: [Why this approach was chosen]
  - **Alternatives considered**: [What else was evaluated]
  - **Impact**: [What this affects going forward]

## Step 5 — Quality Gate Status

Run and report the quality gate results:

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

Report: PASS / FAIL with details on any remaining issues.

## Step 6 — Remaining Work

List any incomplete tasks or known issues:

- [ ] [Task that was started but not finished]
- [ ] [Known issue discovered during work]
- [ ] [Follow-up task needed]

## Step 7 — Output the Summary

Format for `SESSION_LOG.md`:

```markdown
---

## Session: YYYY-MM-DD HH:MM

### Summary
[One-paragraph overview of what was accomplished]

### Changes
- **Created**: X files
- **Modified**: Y files
- **Deleted**: Z files

### Features
- [Feature list]

### Fixes
- [Bug fix list]

### Tests
- [Test additions]

### Decisions
- [Key decisions]

### Quality Gate
- ruff check: ✅ PASS
- ruff format: ✅ PASS
- Django check: ✅ PASS

### Remaining Work
- [Incomplete items]

### Files Touched
<details>
<summary>Full file list (X files)</summary>

- path/to/file1.py
- path/to/file2.py
</details>
```
