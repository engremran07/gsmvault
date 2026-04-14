---
name: regression-atomic-monitor
description: >-
  Monitors @transaction.atomic on multi-model writes.
  Use when: transaction safety audit, atomic block check, multi-model write scan.
---

# Regression Atomic Monitor

Detects missing `@transaction.atomic` (or `with transaction.atomic()`) on service functions that write to multiple models.

## Rules

1. Any service function that creates/updates more than one model must use `@transaction.atomic` — missing is HIGH.
2. Scan all `apps/*/services.py` and `apps/*/services/*.py` files.
3. Financial operations (wallet, shop, marketplace, bounty) without atomic blocks are CRITICAL.
4. Nested `transaction.atomic()` should use `savepoint=True` (default) — explicitly setting `savepoint=False` is HIGH.
5. Signal handlers that write to DB should not be inside the caller's atomic block to avoid deadlocks.
6. Report each violation with function name, file, and the models being written.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
