---
name: regression-clickjacking-monitor
description: >-
  Monitors clickjacking protection: X-Frame-Options, CSP.
  Use when: clickjacking audit, iframe protection check, frame-ancestors scan.
---

# Regression Clickjacking Monitor

Detects clickjacking protection regressions: weakened X-Frame-Options, removed frame-ancestors CSP directive.

## Rules

1. `X_FRAME_OPTIONS = "DENY"` must be set — change to `SAMEORIGIN` or removal is HIGH.
2. CSP `frame-ancestors 'none'` or `frame-ancestors 'self'` must be present — removal is HIGH.
3. `django.middleware.clickjacking.XFrameOptionsMiddleware` must be in MIDDLEWARE — removal is CRITICAL.
4. Verify no view uses `@xframe_options_exempt` without documented justification.
5. Verify no view uses `@xframe_options_sameorigin` without a specific iframe embedding need.
6. Check that embed/iframe pages are explicitly opted-in, not opted-out of protection.
7. Flag any `X-Frame-Options` header override in custom middleware or view responses.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
