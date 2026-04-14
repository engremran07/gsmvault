---
name: pii-leak-detector
description: >-
  Detects PII in logs, responses, error messages. Use when: PII exposure scan, personal data leak, GDPR data protection audit.
---

# PII Leak Detector

Scans codebase for potential PII (Personally Identifiable Information) exposure in logs, error responses, API output, and debug messages.

## Scope

- All `apps/**/*.py` files
- `app/settings*.py`
- `templates/**/*.html`

## Rules

1. Log statements must never include passwords, tokens, API keys, or session IDs
2. Log statements must never include full email addresses — mask as `u***@domain.com`
3. Log statements must never include full IP addresses in production — hash with `hash_ip()` from `apps.consent.utils`
4. Error responses must not expose internal state: stack traces, variable values, SQL queries
5. API error responses must only include safe error codes and messages — never raw exception text
6. User-Agent strings must be hashed in logs using `hash_ua()` from `apps.consent.utils`
7. Django `DEBUG = True` must never be set in production — leaks full context on errors
8. `string_if_invalid` in TEMPLATES must not expose variable names in production
9. DRF exception handler must strip sensitive data before logging
10. Payment/wallet transaction logs must not include full credit card or bank details

## Procedure

1. Grep for `logger.` and `logging.` calls that include user data variables
2. Grep for `print()` statements that may leak data
3. Check error handler implementations for data exposure
4. Verify DEBUG setting in production config
5. Check API exception handlers for data stripping
6. Search for email, password, token, key in log format strings

## Output

PII exposure report with file, line, data type exposed, and remediation.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
