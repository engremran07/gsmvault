---
name: sql-raw-query-detector
description: >-
  Scans for raw(), extra(), RawSQL in codebase. Use when: raw query detection, deprecated query method scan, SQL safety scan.
---

# SQL Raw Query Detector

Focused scanner that detects all instances of `.raw()`, `.extra()`, `RawSQL`, and direct cursor usage across the codebase.

## Scope

- All `apps/**/*.py` files
- `scripts/*.py`
- `conftest.py`

## Rules

1. `.raw()` on any QuerySet is a violation — must be replaced with ORM equivalent
2. `.extra()` is deprecated since Django 3.2 — must be migrated to `annotate()`/`Subquery()`
3. `RawSQL()` expression must be replaced with `Func()`, `Value()`, `Case()`/`When()`
4. `connection.cursor()` is only acceptable in migration `RunPython` functions
5. `django.db.connection` import outside migrations is suspicious — flag for review
6. f-strings or `.format()` used in any SQL-adjacent context is CRITICAL severity
7. Test files that use raw SQL for setup are acceptable but should be flagged for improvement
8. `cursor.callproc()` for stored procedures must be replaced with ORM or removed
9. Any raw SQL must be parameterized if absolutely unavoidable — never string concatenation
10. SQL comments in code (`-- DROP TABLE`) must be removed — they indicate past raw SQL usage

## Procedure

1. Grep for `.raw(` across all Python files
2. Grep for `.extra(` across all Python files
3. Grep for `RawSQL` imports and usage
4. Grep for `connection.cursor` and `cursor.execute`
5. Grep for raw SQL keywords in string literals near database imports
6. Report each finding with replacement recommendation

## Output

Raw query detection report with file, line, method found, and specific ORM replacement.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
