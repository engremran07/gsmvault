---
name: regression-select-for-update-monitor
description: >-
  Monitors select_for_update() on financial operations.
  Use when: financial safety audit, wallet operation check, race condition scan.
---

# Regression Select For Update Monitor

Detects missing `select_for_update()` on financial and wallet operations, which can cause race conditions.

## Rules

1. Every wallet balance read-modify-write must use `select_for_update()` — missing is CRITICAL.
2. Every credit/debit operation in `apps/wallet/` must lock the row first.
3. Every marketplace escrow operation must use `select_for_update()`.
4. Every bounty payout operation must lock the wallet record.
5. Scan `apps/wallet/services.py`, `apps/shop/services.py`, `apps/marketplace/services.py`, `apps/bounty/services.py`.
6. Flag any `.get()` or `.filter()` on wallet-related models inside `@transaction.atomic` without `select_for_update()`.
7. Report each violation with the exact function, file, and line.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
