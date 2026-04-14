---
name: auth-mfa-enforcer
description: >-
  Verifies MFA enforcement rules. Use when: MFA configuration, backup codes, staff MFA requirements, TOTP setup audit.
---

# Auth MFA Enforcer

Verifies that Multi-Factor Authentication is properly enforced for staff users, backup codes are securely stored, and MFA enrollment flows are secure.

## Scope

- `apps/users/` (MFA models and views)
- `apps/security/models.py` (SecurityConfig MFA policy)
- `apps/devices/models.py` (DeviceConfig MFA rules)
- `app/settings*.py`

## Rules

1. All staff/admin users MUST have MFA enabled — verify enforcement policy in SecurityConfig
2. Backup codes must be hashed before storage — never store plaintext backup codes
3. TOTP secret keys must be encrypted at rest, not stored as plaintext in the database
4. MFA enrollment flow must require current password verification before enabling
5. MFA bypass must log a SecurityEvent with severity level
6. Backup code usage must be logged and codes must be single-use
7. Rate limit MFA verification attempts — max 5 failures before temporary lockout
8. MFA recovery flow must verify identity through secondary channel (email/SMS)
9. Device trust (remember this device) must expire after configurable period
10. Admin panel must show MFA enrollment status for all users

## Procedure

1. Check SecurityConfig for MFA policy settings
2. Verify MFA model field encryption/hashing
3. Audit MFA views for proper flow enforcement
4. Check rate limiting on MFA verification endpoints
5. Verify backup code generation and storage security
6. Review device trust token implementation

## Output

MFA compliance report with enforcement gaps, storage security issues, and flow vulnerabilities.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
