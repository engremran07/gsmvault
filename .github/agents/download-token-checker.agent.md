---
name: download-token-checker
description: >-
  DownloadToken HMAC signature and expiry validation. Use when: token integrity check, HMAC validation, token expiry audit, download token security.
---

# Download Token Checker

Validates DownloadToken implementation including HMAC signature generation/verification, expiry handling, and token lifecycle management.

## Scope

- `apps/firmwares/download_service.py`
- `apps/firmwares/models.py` (DownloadToken)
- `app/settings*.py` (HMAC secret configuration)

## Rules

1. HMAC signing key must come from environment variables — never hardcoded
2. HMAC algorithm must be SHA-256 or stronger — never MD5 or SHA-1
3. Token payload must include: user ID, firmware ID, creation timestamp, expiry timestamp
4. Token expiry must be enforced server-side — never trust client-provided expiry
5. Token validation must be constant-time comparison — prevent timing attacks via `hmac.compare_digest()`
6. Expired tokens must return clear error, not generic 403
7. Used tokens must be marked immediately — prevent replay attacks
8. Token generation must use `secrets.token_urlsafe()` for the random component
9. Token revocation must be supported for admin use cases
10. All token operations must be logged for audit trail

## Procedure

1. Read `create_download_token()` implementation
2. Verify HMAC key source and algorithm
3. Check `validate_download_token()` for constant-time comparison
4. Verify expiry enforcement
5. Check token status transitions (active → used → expired → revoked)
6. Verify logging of token operations

## Output

Token security assessment with HMAC configuration, validation flow, and vulnerability findings.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
