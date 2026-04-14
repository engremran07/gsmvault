---
agent: 'agent'
description: 'Plan a production hotfix: identify root cause, minimal fix, regression risk, rollback strategy, and affected tests.'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal']
---

# Hotfix Plan

Plan a minimal, safe production hotfix. The user will describe the bug or provide an error trace.

## Step 1 — Bug Identification

1. Parse the user's bug report or error traceback.
2. Identify the failing file, function, and line number from the traceback.
3. Read the failing code in full context (at least 50 lines around the error).
4. Identify the exact failure mode: exception type, missing data, logic error, or race condition.

## Step 2 — Root Cause Analysis

1. Trace the code path from entry point (view/API/task) to the failure point.
2. Check recent changes to the affected files — use `git log --oneline -20 -- <file>` to see recent commits.
3. Determine if this is:
   - **Data issue**: Missing FK, null field, corrupted data → fix data or add null handling.
   - **Logic error**: Wrong condition, missing branch, incorrect calculation → fix logic.
   - **Race condition**: Concurrent access without `select_for_update()` → add locking.
   - **Import error**: Dissolved app reference, circular import → fix import path.
   - **Type error**: Missing type guard, None not handled → add proper checks.
   - **Security issue**: Missing auth check, XSS, CSRF bypass → apply security fix immediately.

## Step 3 — Minimal Fix Design

Design the smallest possible change that fixes the bug:

- **DO**: Fix exactly the failing code path. Add a guard, fix a condition, add a null check.
- **DO NOT**: Refactor surrounding code, add features, change unrelated logic.
- **DO NOT**: Modify database schema in a hotfix — schema changes require a full release cycle.
- If the fix touches financial code (`apps.wallet`, `apps.shop`, `apps.marketplace`, `apps.bounty`): ensure `select_for_update()` and `@transaction.atomic` are present.
- If the fix touches user input: ensure sanitization with `apps.core.sanitizers.sanitize_html_content()`.
- If the fix touches auth: verify `getattr(request.user, "is_staff", False)` pattern for anonymous safety.

## Step 4 — Regression Risk Assessment

Evaluate what could break:

1. Search for all callers of the changed function: `grep_search` for the function name.
2. Check if the changed file is imported elsewhere: `grep_search` for `from <module> import`.
3. Identify tests that cover the changed code: search `tests/` and `apps/*/tests*.py`.
4. Rate regression risk:
   - **Low**: Change is purely additive (new guard clause, null check).
   - **Medium**: Change modifies existing logic but has test coverage.
   - **High**: Change modifies logic in untested code or touches multiple callers.
   - **Critical**: Change touches financial, auth, or security code.

## Step 5 — Test the Fix

1. Identify existing tests for the affected code.
2. If tests exist: verify they pass with the fix applied.
3. If no tests exist: write a minimal regression test that reproduces the bug and verifies the fix.
4. Run the quality gate:

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## Step 6 — Rollback Plan

Document how to undo the fix if it causes problems:

- If code-only change: revert the commit (`git revert <sha>`).
- If migration was added (should not happen in hotfix): document the reverse migration command.
- If data was modified: document the reverse data operation.

## Step 7 — Output the Hotfix Plan

```markdown
## Hotfix: [Brief Description]

### Bug
- **Symptom**: [What the user sees]
- **Root Cause**: [Why it happens]
- **Affected File(s)**: [Exact paths]

### Fix
- **Change**: [Exact description of code change]
- **Lines Changed**: [File:line_start-line_end]
- **Regression Risk**: [Low/Medium/High/Critical]

### Testing
- [ ] Existing tests pass
- [ ] Regression test added for this bug
- [ ] Quality gate passes (ruff + Django check)

### Rollback
- `git revert <commit_sha>` to undo

### Deployment Notes
- [Any special deployment considerations]
```
