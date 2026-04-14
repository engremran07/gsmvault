---
name: secret-env-checker
description: >-
  Verifies all secrets use environment variables. Use when: env var audit, .env.sample completeness, settings credential check.
---

# Secret Env Checker

Verifies that all secrets and credentials are loaded from environment variables, and that `.env.sample` documents all required variables.

## Scope

- `app/settings.py`, `app/settings_dev.py`, `app/settings_production.py`
- `.env`, `.env.sample`, `.env.example`
- `.gitignore`

## Rules

1. `SECRET_KEY` must come from `os.environ` or `decouple.config()` — never hardcoded
2. `DATABASE_URL` or `DATABASES` credentials must use env vars
3. Email backend credentials (SMTP password) must use env vars
4. Third-party API keys (Stripe, SendGrid, etc.) must use env vars
5. `.env` files must be in `.gitignore` — verify they are never committed
6. `.env.sample` must list ALL required env vars with placeholder values (not real secrets)
7. Default values for secrets must be obviously fake: `"change-me"`, `"your-key-here"`
8. `DEBUG` must default to `False` in production settings
9. `ALLOWED_HOSTS` must not contain wildcards (`*`) in production
10. Redis/Celery broker URLs with passwords must use env vars

## Procedure

1. Parse all settings files for credential assignments
2. Verify each uses `os.environ.get()`, `os.environ[]`, or `decouple.config()`
3. Compare required env vars against `.env.sample` entries
4. Check `.gitignore` for `.env` patterns
5. Verify no default values are real credentials

## Output

Environment variable compliance report with missing vars, hardcoded values, and .env.sample gaps.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
