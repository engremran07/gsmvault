---
name: password-policy-checker
description: >-
  Password validator configuration and strength requirements. Use when: password policy audit, validator config, password strength, password hashing.
---

# Password Policy Checker

Audits password validation configuration, hashing algorithm selection, and password strength enforcement.

## Scope

- `app/settings*.py` (AUTH_PASSWORD_VALIDATORS, PASSWORD_HASHERS)
- `apps/users/forms.py`
- `apps/users/views.py`

## Rules

1. `AUTH_PASSWORD_VALIDATORS` must include `MinimumLengthValidator` with min_length ≥ 12
2. `AUTH_PASSWORD_VALIDATORS` must include `CommonPasswordValidator`
3. `AUTH_PASSWORD_VALIDATORS` must include `UserAttributeSimilarityValidator`
4. `AUTH_PASSWORD_VALIDATORS` must include `NumericPasswordValidator`
5. `PASSWORD_HASHERS` must list Argon2 or bcrypt first — never plain PBKDF2 alone
6. Password change forms must require current password verification
7. Password reset tokens must expire within 24 hours
8. Failed login attempts must trigger account lockout after configurable threshold
9. Password history must prevent reuse of last N passwords (configurable)
10. Password strength meter should be shown on registration and change forms

## Procedure

1. Read AUTH_PASSWORD_VALIDATORS from settings
2. Read PASSWORD_HASHERS configuration
3. Check password change/reset view implementations
4. Verify login attempt throttling
5. Check for password history enforcement
6. Verify password field does not echo back in API responses

## Output

Password policy compliance report with validator list, hasher configuration, and strength assessment.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
