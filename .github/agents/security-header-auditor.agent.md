---
name: security-header-auditor
description: >-
  HTTP security headers auditor. Use when: HSTS, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, security header review.
---

# Security Header Auditor

Audits HTTP security response headers across the platform for completeness and correctness.

## Scope

- `app/settings*.py`
- `app/middleware/*.py`
- `apps/security/models.py` (SecurityConfig)

## Rules

1. `SECURE_HSTS_SECONDS` must be set to at least `31536000` (1 year) in production
2. `SECURE_HSTS_INCLUDE_SUBDOMAINS = True` must be set in production
3. `SECURE_HSTS_PRELOAD = True` should be set after confirming all subdomains support HTTPS
4. `SECURE_CONTENT_TYPE_NOSNIFF = True` must be set — prevents MIME type sniffing
5. `SECURE_BROWSER_XSS_FILTER = True` should be set for legacy browser protection
6. `SECURE_SSL_REDIRECT = True` must be set in production — forces HTTPS
7. `Referrer-Policy` header should be `strict-origin-when-cross-origin` or stricter
8. `Permissions-Policy` header should restrict unnecessary browser features (camera, microphone, geolocation)
9. `X-Content-Type-Options: nosniff` must be present on all responses
10. Security headers must not be overridden by individual views unless documented

## Procedure

1. Read all security-related settings from settings files
2. Check middleware for custom security header injection
3. Verify HSTS configuration
4. Check Referrer-Policy and Permissions-Policy
5. Compare dev vs production security header settings
6. Verify headers are not stripped by middleware ordering

## Output

Security header compliance matrix with header name, expected value, actual value, and status.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
