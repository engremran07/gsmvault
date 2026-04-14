---
name: regression-celery-config-monitor
description: >-
  Monitors Celery task configuration: retries, idempotency.
  Use when: Celery audit, task config check, retry policy scan.
---

# Regression Celery Config Monitor

Detects Celery task configuration regressions: missing retry policies, non-idempotent tasks, broken task routing.

## Rules

1. Every Celery task should have `max_retries` configured — missing is MEDIUM.
2. Tasks that call external APIs must have `autoretry_for` with appropriate exception list.
3. Retry backoff should use exponential backoff (`retry_backoff=True`) — fixed delay is MEDIUM.
4. Tasks must be idempotent — running the same task twice must not corrupt data.
5. Verify `app.celery` configuration is intact: broker URL, result backend, task serializer.
6. Check that task imports use the correct app path after consolidation.
7. Flag any task that catches all exceptions and silently succeeds.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
