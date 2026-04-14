---
name: regression-test-coverage
description: "Test coverage regression detection skill. Use when: verifying test coverage isn't decreasing, checking new code has tests, detecting removed test files, scanning for skipped tests."
---

# Test Coverage Regression Detection

## When to Use

- After adding new service functions or views
- After modifying existing tested code
- After deleting or renaming test files
- Before merging branches

## Guards to Verify

| Rule | Guard | Critical |
|------|-------|----------|
| Coverage floor | 60% minimum (pyproject.toml `--cov-fail-under=60`) | YES |
| New services tested | Each public service function has a test | MEDIUM |
| API endpoints tested | DRF viewsets have test classes | MEDIUM |
| Model tests | New models have basic CRUD tests | LOW |

## Procedure

1. Check if any test files were deleted or renamed
2. Verify new service functions have corresponding test functions
3. Verify new API viewsets have test classes
4. Run `pytest --cov` and check coverage doesn't drop
5. Search for `@pytest.mark.skip` — each must have a documented reason

## Red Flags

- Test file deleted without replacement
- New `services.py` function with no test
- `@pytest.mark.skip` without reason string
- Coverage dropped below 60%
- `# pragma: no cover` on complex business logic

## Verification Commands

```powershell
# Run tests with coverage
& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-report=term-missing

# Check coverage floor
& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-fail-under=60
```

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
