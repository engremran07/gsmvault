---
name: regression-app-boundary-monitor
description: >-
  Monitors app boundary violations: cross-imports.
  Use when: architecture audit, app isolation check, cross-import regression scan.
---

# Regression App Boundary Monitor

Detects app boundary violations: forbidden cross-app imports in models.py and services.py files.

## Rules

1. `models.py` must NEVER import models from another app (except `apps.core`, `apps.site_settings`, `AUTH_USER_MODEL`) — violation is CRITICAL.
2. `services.py` must NEVER directly import services from another app — use EventBus or signals instead.
3. `apps.core.*` is allowed everywhere — it is shared infrastructure.
4. `apps.site_settings.*` is allowed everywhere — it is global config.
5. `apps/admin/` is the ONLY app allowed to import from ALL other apps.
6. Views CAN import from multiple apps — they are orchestrators.
7. Flag circular imports between any two non-core apps as CRITICAL.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
