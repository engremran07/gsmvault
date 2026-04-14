---
name: regression-test-coverage-monitor
description: >-
  Monitors test coverage: removed tests, skipped tests.
  Use when: test coverage audit, test file check, removed test detection.
---

# Regression Test Coverage Monitor

Detects test coverage regressions: removed test files, added `@pytest.mark.skip` without reason, decreased coverage.

## Rules

1. Deleted test files without replacement are HIGH severity.
2. New `@pytest.mark.skip` or `@unittest.skip` decorators must have a documented reason — missing reason is HIGH.
3. New `pytest.mark.xfail` must have a linked issue — undocumented is MEDIUM.
4. Every new service function should have corresponding test coverage.
5. Every new view should have at least a smoke test (status 200 response).
6. Verify `conftest.py` fixtures are not removed without updating dependent tests.
7. Report coverage delta: files with decreased test coverage since last commit.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
