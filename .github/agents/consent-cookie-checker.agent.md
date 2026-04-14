---
name: consent-cookie-checker
description: >-
  Consent cookie configuration and compliance checker. Use when: consent cookie flags, cookie banner, GDPR cookie audit.
---

# Consent Cookie Checker

Verifies consent cookie configuration, storage format, and compliance with privacy regulations.

## Scope

- `apps/consent/views.py`
- `apps/consent/utils.py`
- `apps/consent/middleware.py`
- `app/settings*.py`
- `templates/consent/*.html`

## Rules

1. Consent cookie must have `SameSite=Lax` attribute
2. Consent cookie must have appropriate `max_age` — typically 365 days per GDPR guidance
3. Consent cookie must be `HttpOnly` if only read server-side
4. Consent cookie value must be signed or integrity-checked — prevent client manipulation
5. Cookie must store consent decisions per scope (functional, analytics, seo, ads)
6. Default state must be "not consented" — pre-checked consent is invalid under GDPR
7. Consent cookie must not contain PII — only consent flags and timestamp
8. Cookie banner must be shown until explicit consent action — no dismiss-to-accept
9. Consent withdrawal must clear all non-essential cookies
10. Consent timestamp must be stored for compliance auditing

## Procedure

1. Read consent cookie implementation in views and utils
2. Check cookie attributes (SameSite, HttpOnly, Secure, max_age)
3. Verify cookie value format and integrity protection
4. Check default consent state
5. Verify consent withdrawal clears relevant cookies
6. Check cookie banner template for compliance

## Output

Consent cookie compliance report with attribute values, regulatory compliance, and issues.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
