---
name: regression-htmx-error-monitor
description: >-
  Monitors HTMX error handling: status code handlers.
  Use when: HTMX error audit, response error check, HTMX failure handling scan.
---

# Regression HTMX Error Monitor

Detects HTMX error handling regressions: removed error event listeners, missing status code handlers, silent HTMX failures.

## Rules

1. Verify `htmx:responseError` event handler is configured globally — removal is HIGH.
2. Verify 4xx and 5xx responses from HTMX requests are surfaced to the user.
3. Check that network error handling exists for HTMX requests.
4. Verify timeout configuration is set for HTMX requests via `hx-request` or global config.
5. Flag any HTMX endpoint that silently swallows errors without user feedback.
6. Ensure error responses include appropriate HTMX swap content, not raw JSON.
7. Verify HTMX 401/403 responses trigger re-authentication flow, not blank content.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
