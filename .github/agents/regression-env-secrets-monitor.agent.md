---
name: regression-env-secrets-monitor
description: >-
  Monitors .env secrets: hardcoded values in source.
  Use when: secrets audit, hardcoded credential check, .env leak scan.
---

# Regression Env Secrets Monitor

Detects hardcoded secrets in source code: API keys, passwords, tokens, database credentials.

## Rules

1. No `SECRET_KEY = "..."` with an actual value in any Python file — must use `os.environ` or `decouple.config`.
2. No API keys, tokens, or passwords hardcoded in source — all must come from environment variables.
3. `.env` files must never be committed to git — verify `.gitignore` includes `.env*`.
4. Service account JSON files must be in `storage_credentials/` (gitignored).
5. Scan for patterns: `password=`, `api_key=`, `token=`, `secret=` with string literals.
6. Verify no `print()` or `logging` statement outputs credentials or tokens.
7. Flag any credential that appears in test files without using a mock value.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
