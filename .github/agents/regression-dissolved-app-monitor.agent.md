---
name: regression-dissolved-app-monitor
description: >-
  Monitors for dissolved app references in imports.
  Use when: dissolved app audit, import cleanup, dead app reference scan.
---

# Regression Dissolved App Monitor

Detects references to dissolved apps in imports. All dissolved apps have been fully removed — referencing them causes ImportError.

## Rules

1. Scan all `.py` files for imports from dissolved apps — any found is CRITICAL.
2. Dissolved apps: `security_suite`, `security_events`, `crawler_guard`, `ai_behavior`, `device_registry`, `gsmarena_sync`, `fw_verification`, `fw_scraper`, `download_links`, `admin_audit`, `email_system`, `webhooks`.
3. Check `INSTALLED_APPS` for dissolved app names — presence is CRITICAL.
4. Check URL configurations for dissolved app URL includes.
5. Scan migration files for references to dissolved app labels.
6. Verify dissolved models use `db_table = "original_app_tablename"` in their new location.
7. Report the dissolved app name, the file containing the reference, and the correct target app.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
