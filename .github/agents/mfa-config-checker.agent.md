---
name: mfa-config-checker
description: >-
  MFA configuration auditor. Use when: TOTP setup, backup codes, MFA enforcement policy, multi-factor auth review.
---

# MFA Config Checker

Audits Multi-Factor Authentication configuration including TOTP setup, backup code generation, and enforcement policies.

## Scope

- `apps/users/models.py` (MFA-related fields)
- `apps/users/views.py` (MFA setup/verify views)
- `apps/security/models.py` (SecurityConfig — MFA policy)
- `app/settings*.py`

## Rules

1. MFA must be enforceable per-role: staff users MUST be required to enable MFA
2. TOTP secret must be stored encrypted at rest — never plain text in database
3. TOTP verification must use time-window tolerance of ±1 period (30 seconds) only
4. Backup codes must be generated as one-time-use — marked as used after consumption
5. Backup codes must be at least 8 characters of cryptographic randomness
6. MFA setup must require password re-verification before enabling
7. MFA disable must require current TOTP code or backup code — not just password
8. Recovery flow must have admin approval for MFA reset when all codes are lost
9. MFA enforcement policy must be configured via SecurityConfig singleton
10. Failed MFA attempts must be rate-limited and logged as SecurityEvent

## Procedure

1. Check SecurityConfig for MFA enforcement policy
2. Read MFA model fields for secret storage (encryption check)
3. Verify TOTP verification implementation (time window, algorithm)
4. Check backup code generation and one-time-use enforcement
5. Verify MFA setup requires password re-verification
6. Check failed attempt logging and rate limiting

## Output

MFA configuration report with enforcement policy, secret storage, and security compliance.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
