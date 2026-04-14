---
name: regression-alpine-store-monitor
description: >-
  Monitors Alpine store integrity and initialization.
  Use when: Alpine store audit, store init check, global state regression scan.
---

# Regression Alpine Store Monitor

Detects Alpine.js store regressions: removed store registrations, broken store initialization order, missing store dependencies.

## Rules

1. Verify all `Alpine.store()` registrations happen before `Alpine.start()` — order violation is CRITICAL.
2. Check that store definitions in `static/js/` are loaded in the correct script order.
3. Verify no store is referenced before its registration via `$store`.
4. Flag any store that directly mutates DOM instead of using reactive state.
5. Verify store persistence patterns use safe localStorage access with fallbacks.
6. Check that `Alpine.data()` component registrations are not conflicting with store names.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
