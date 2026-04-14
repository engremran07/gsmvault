---
name: regression-csp-monitor
description: >-
  Monitors CSP headers: weakened policies, missing nonces.
  Use when: CSP audit, nonce check, Content-Security-Policy regression scan.
---

# Regression CSP Monitor

Detects CSP regressions: weakened Content-Security-Policy directives, missing nonces on inline scripts, removed CSP middleware.

## Rules

1. Verify CSP nonce middleware (`app.middleware.csp_nonce`) is in MIDDLEWARE — removal is CRITICAL.
2. Every inline `<script>` tag must have `nonce="{{ csp_nonce }}"` — missing is CRITICAL.
3. Verify CSP does not contain `unsafe-inline` for script-src in production — presence is CRITICAL.
4. Verify CSP does not contain `unsafe-eval` — presence is HIGH.
5. Check that `CSPViolationReport` model endpoint is configured for report collection.
6. Verify `strict-dynamic` is used correctly with nonce-based policy.
7. Flag any CSP header weakening compared to the baseline policy.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
