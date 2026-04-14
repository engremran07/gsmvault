---
name: api-auth-checker
description: >-
  Verifies API authentication is configured on all endpoints. Use when: missing API auth, unauthenticated API access, auth class audit.
---

# API Auth Checker

Verifies that authentication is properly configured on all DRF API endpoints, with no endpoints accidentally left open.

## Scope

- `apps/*/api.py`
- `apps/api/urls.py`
- `app/settings*.py` (REST_FRAMEWORK DEFAULT_AUTHENTICATION_CLASSES)

## Rules

1. Every APIView/ViewSet must have `authentication_classes` defined or inherit sensible defaults
2. `AllowAny` permission must be explicitly justified with a comment explaining why
3. Public endpoints (health checks, public data) must still have throttling even without auth
4. JWT authentication must validate token expiry, signature, and issuer
5. Session authentication is allowed for HTMX API calls from Django-rendered pages
6. Token authentication must use hashed tokens — never store plaintext API tokens
7. Authentication bypass via header manipulation must be prevented (no trusting `X-User-ID` headers)
8. Failed authentication must return HTTP 401, not 403 — distinguish "who are you" from "you can't do this"
9. Authentication classes must be tested with expired, malformed, and missing credentials
10. API endpoints must not accept authentication via query parameters (tokens in URLs leak in logs)

## Procedure

1. Read REST_FRAMEWORK default authentication configuration
2. Enumerate all API views and check explicit authentication_classes
3. Identify views with `AllowAny` or no authentication
4. Verify JWT configuration (expiry, algorithm, secret)
5. Check for authentication via query parameters
6. Test authentication error responses

## Output

API authentication coverage report with endpoint, auth classes, and compliance status.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
