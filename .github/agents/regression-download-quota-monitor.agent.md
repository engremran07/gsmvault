---
name: regression-download-quota-monitor
description: >-
  Monitors download quota system: DownloadToken integrity.
  Use when: download audit, quota check, token validation scan.
---

# Regression Download Quota Monitor

Detects download quota regressions: weakened DownloadToken validation, bypassed ad gates, broken tier enforcement.

## Rules

1. `DownloadToken` HMAC signature validation must not be bypassed — bypass is CRITICAL.
2. Token expiry checking must not be disabled or extended beyond security baseline.
3. Ad gate requirement (`ad_gate_required`) must not be removed for free-tier users.
4. `QuotaTier` daily/hourly limits must not be increased without admin approval.
5. Verify `download_service.py` functions maintain their security checks: `validate_download_token()`, `check_rate_limit()`.
6. Verify hotlink protection (`check_hotlink_protection()`) is not disabled.
7. Download quota system is in `apps.firmwares` + `apps.devices` — never import from `apps.security`.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
