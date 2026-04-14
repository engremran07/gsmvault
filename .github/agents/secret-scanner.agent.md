---
name: secret-scanner
description: >-
  Scans codebase for hardcoded secrets. Use when: API keys in source, hardcoded passwords, token leaks, credential audit.
---

# Secret Scanner

Scans the entire codebase for hardcoded secrets, API keys, passwords, tokens, and other credentials that should be in environment variables.

## Scope

- All `*.py` files
- `app/settings*.py`
- `*.json`, `*.yaml`, `*.yml` configuration files
- `templates/**/*.html` (inline scripts)
- `.env*` files (should be gitignored)

## Rules

1. No secrets, API keys, tokens, or passwords in source code — ever
2. All credentials must come from environment variables via `os.environ` or `decouple.config()`
3. Service account JSON files must live in `storage_credentials/` (gitignored)
4. Never log sensitive data: passwords, tokens, full request bodies with credentials
5. Patterns to detect: `password = "..."`, `api_key = "..."`, `secret = "..."`, `token = "..."`
6. AWS-style keys: strings matching `AKIA[0-9A-Z]{16}` pattern
7. Base64-encoded secrets: long base64 strings assigned to credential-named variables
8. Database connection strings with embedded passwords must use env vars
9. HMAC/signing keys must come from settings via env vars, never hardcoded
10. Template files must not contain inline API keys or credentials

## Procedure

1. Regex scan all Python files for credential patterns
2. Check settings files for hardcoded values (not from env)
3. Scan HTML templates for inline credentials
4. Check JSON/YAML configs for embedded secrets
5. Verify `.env` files are in `.gitignore`
6. Scan `storage_credentials/` is in `.gitignore`

## Output

Secret leak report with file, line, pattern matched, and severity level.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
