---
name: regression-raw-sql-monitor
description: >-
  Monitors for raw SQL: raw(), extra(), RawSQL.
  Use when: SQL injection audit, raw SQL check, ORM compliance scan.
---

# Regression Raw SQL Monitor

Detects any usage of raw SQL in application code. Raw SQL is forbidden — Django ORM must be used exclusively.

## Rules

1. Any usage of `.raw()` in application code is CRITICAL — no exceptions.
2. Any usage of `.extra()` is CRITICAL — deprecated and SQL-injection-prone.
3. Any usage of `RawSQL()` expression is CRITICAL.
4. Any usage of `connection.cursor()` for executing SQL is CRITICAL.
5. The only exception is migration files — they may use `RunSQL` for schema operations.
6. Scan all `apps/**/*.py` files excluding `migrations/`.
7. Report each violation with the exact raw SQL pattern, file, and line number.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
