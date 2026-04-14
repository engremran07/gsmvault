---
name: logging-secrets-checker
description: >-
  Scans logging statements for sensitive data exposure. Use when: logging audit, secret leak in logs, sensitive data in output.
---

# Logging Secrets Checker

Focused scan of all logging, print, and output statements for accidental exposure of secrets, credentials, and tokens.

## Scope

- All `apps/**/*.py` files
- `scripts/*.py`
- `apps/*/management/commands/*.py`

## Rules

1. `logger.debug()`, `logger.info()`, `logger.error()` must not include `password`, `secret`, `token`, `key` variable values
2. `print()` statements must not exist in production code — use `logger` instead
3. Exception logging must use `logger.exception()` which logs traceback without exposing local variables
4. f-strings in log messages must not interpolate credentials: `f"API key: {api_key}"` is CRITICAL
5. `repr()` of request objects must not be logged — may contain auth headers
6. `request.META` must not be logged in full — contains `HTTP_AUTHORIZATION`, cookies
7. `request.POST` must not be logged in full — contains passwords and CSRF tokens
8. Celery task arguments must not be logged if they contain sensitive data
9. Webhook payload logging must redact authentication headers
10. All logging of user actions must use consent-aware hashing for IP and User-Agent

## Procedure

1. Grep for `logger.` with variable interpolation containing sensitive names
2. Grep for `print(` in non-test, non-management-command files
3. Check exception handlers for broad data logging
4. Search for `request.META`, `request.POST`, `request.COOKIES` in log statements
5. Check Celery task logging for argument exposure
6. Verify webhook and API integration logging

## Output

Logging secrets exposure report with severity, file, line, and safe replacement pattern.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
