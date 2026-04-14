---
name: sql-injection-auditor
description: >-
  Raw SQL detection and ORM enforcement. Use when: SQL injection audit, raw SQL scan, ORM-only enforcement, database query safety.
---

# SQL Injection Auditor

Scans the entire codebase for raw SQL usage and verifies that all database access uses Django ORM exclusively.

## Scope

- All `apps/**/*.py` files
- `scripts/*.py`
- `apps/*/management/commands/*.py`

## Rules

1. No raw SQL anywhere in application code — Django ORM exclusively
2. `cursor.execute()` is FORBIDDEN — use ORM methods instead
3. `.raw()` queryset method is FORBIDDEN — use `filter()`, `annotate()`, `aggregate()`
4. `.extra()` is deprecated and FORBIDDEN — use `annotate()` with `F()`, `Q()`, `Subquery()`
5. `RawSQL()` expression is FORBIDDEN — use `Func()`, `Value()`, `Case()`/`When()` instead
6. String formatting in any ORM filter is suspicious: `.filter(name=f"{user_input}")` is safe but `.extra(where=[f"name='{user_input}'"])` is injection
7. Management commands that import data must use ORM `bulk_create()`, not raw INSERT
8. Migration `RunSQL` is the ONLY acceptable use of raw SQL — and must be parameterized
9. Database functions must use Django's database function wrappers
10. Any exception to this rule must be documented with security justification and approved

## Procedure

1. Grep for `cursor.execute`, `.raw(`, `.extra(`, `RawSQL`, `connection.cursor`
2. Grep for SQL keywords in string literals: `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `DROP`
3. Check management commands for raw database access
4. Verify migration files use parameterized `RunSQL` when necessary
5. Check for string formatting in ORM filter arguments

## Output

Raw SQL violation report with file, line, pattern, and ORM-based replacement recommendation.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
