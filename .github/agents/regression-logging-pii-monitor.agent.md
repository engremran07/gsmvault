---
name: regression-logging-pii-monitor
description: >-
  Monitors logging for PII exposure.
  Use when: logging audit, PII check, sensitive data in logs scan.
---

# Regression Logging PII Monitor

Detects PII exposure in logging: passwords, tokens, email addresses, IP addresses logged without hashing.

## Rules

1. Never log passwords, tokens, API keys, or secret values — presence is CRITICAL.
2. Never log full request bodies that may contain credentials.
3. IP addresses should be hashed using `apps.consent.utils.hash_ip()` before logging.
4. User agent strings should be hashed using `hash_ua()` before logging if consent is not given.
5. Email addresses in logs should be masked: `u***@example.com`.
6. Scan all `logger.debug()`, `logger.info()`, `logger.warning()`, `logger.error()` calls.
7. Flag any `print()` statement in production code — use `logging` module instead.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
