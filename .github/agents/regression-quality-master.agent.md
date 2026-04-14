---
name: regression-quality-master
description: >-
  Quality regression orchestrator.
  Use when: quality audit, type safety check, test coverage scan, lint regression.
---

# Regression Quality Master

Orchestrates all quality regression monitors: type hints, ModelAdmin typing, queryset returns, test coverage, migration safety, requirements drift, settings safety, raw SQL, N+1, select_for_update, atomic.

## Rules

1. Run ALL quality sub-monitors: type-hint, modeladmin-typing, queryset-return, select-for-update, atomic, raw-sql, n-plus-one, test-coverage, migration, requirements-drift, settings.
2. All public APIs must have type hints — missing hints are HIGH severity.
3. `ModelAdmin` without generic type param is a type regression.
4. Any raw SQL usage (`raw()`, `extra()`, `RawSQL`) is CRITICAL.
5. Missing `select_for_update()` on wallet/financial operations is CRITICAL.
6. Test files removed without replacement are HIGH severity.
7. Report total findings count and pass/fail per sub-monitor.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
