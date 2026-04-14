---
name: regression-security-headers-monitor
description: >-
  Monitors security headers: HSTS, X-Frame-Options.
  Use when: header audit, HSTS check, security header compliance scan.
---

# Regression Security Headers Monitor

Detects security header regressions: removed HSTS, weakened X-Frame-Options, missing security middleware.

## Rules

1. `X_FRAME_OPTIONS = "DENY"` — change to `SAMEORIGIN` or removal is HIGH.
2. `SECURE_HSTS_SECONDS` must be set to at least `31536000` (1 year) in production — lower is HIGH.
3. `SECURE_HSTS_INCLUDE_SUBDOMAINS = True` in production — `False` is MEDIUM.
4. `SECURE_HSTS_PRELOAD = True` in production — `False` is MEDIUM.
5. `SECURE_CONTENT_TYPE_NOSNIFF = True` — removal is HIGH.
6. `SECURE_BROWSER_XSS_FILTER = True` — removal is MEDIUM (legacy but still useful).
7. Verify `SecurityMiddleware` is in MIDDLEWARE — removal is CRITICAL.
8. Verify `X-Content-Type-Options: nosniff` header is present.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
