---
name: regression-app-boundaries
description: "App boundary regression detection skill. Use when: verifying cross-app import rules, checking for dissolved app references, detecting models.py cross-imports, ensuring EventBus usage for cross-app communication."
---

# App Boundary Regression Detection

## When to Use

- After adding imports to `models.py` or `services.py`
- After creating new cross-app functionality
- After refactoring or moving code between apps
- After touching dissolved app code (now in target apps)

## Boundary Rules

### Allowed Cross-App Imports

| Source | May Import From |
|--------|----------------|
| Any file | `apps.core.*`, `apps.site_settings.*`, `settings.AUTH_USER_MODEL` |
| `apps/admin/` | ALL other apps (admin is the orchestration layer) |
| Views (`views.py`) | Multiple apps (views are orchestrators) |
| `apps.consent` decorators | Any file (middleware/decorators are cross-cutting) |

### FORBIDDEN Cross-App Imports

| Source | Must NOT Import |
|--------|----------------|
| `models.py` | Another app's models (except core, site_settings, AUTH_USER_MODEL) |
| `services.py` | Another app's services or models |
| `apps.security` | `DownloadToken`, `DownloadSession` from `apps.firmwares` |
| `apps.firmwares` | `RateLimitRule`, `BlockedIP` from `apps.security` |

## Dissolved Apps — NEVER Reference

These app names must NEVER appear in import statements:
`security_suite`, `security_events`, `crawler_guard`, `ai_behavior`, `device_registry`,
`gsmarena_sync`, `fw_verification`, `fw_scraper`, `download_links`, `admin_audit`,
`email_system`, `webhooks`

## Procedure

1. Search changed `models.py` for imports from other apps
2. Search changed `services.py` for cross-app service calls
3. Grep for dissolved app names in all changed files
4. Verify cross-app communication uses `EventBus` or signals
5. Check that `apps/admin/` is the only app importing broadly

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
