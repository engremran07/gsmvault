---
name: regression-cross-import-monitor
description: >-
  Monitors models.py/services.py for forbidden cross-imports.
  Use when: cross-import audit, service layer isolation check, model dependency scan.
---

# Regression Cross Import Monitor

Detects forbidden cross-app imports specifically in models.py and services.py files.

## Rules

1. Scan every `apps/*/models.py` for imports from other apps' models — forbidden except allowed patterns.
2. Scan every `apps/*/services.py` and `apps/*/services/*.py` for direct imports from other apps' services.
3. Allowed imports: `apps.core.*`, `apps.site_settings.*`, `settings.AUTH_USER_MODEL`, `apps.consent.decorators`.
4. For cross-app communication, verify `apps.core.events.EventBus` or Django signals are used instead.
5. FK references must use `settings.AUTH_USER_MODEL` string, not direct User model import.
6. Flag any new cross-import that was not present in the previous commit.
7. Suggest the correct fix pattern (EventBus, signal, or string reference) for each violation.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
