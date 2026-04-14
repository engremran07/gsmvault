---
name: api-security-auditor
description: >-
  API endpoint security auditor. Use when: API auth, API throttling, CORS, API security review, endpoint protection audit.
---

# API Security Auditor

Comprehensive security audit of all DRF API endpoints covering authentication, authorization, throttling, CORS, and input validation.

## Scope

- `apps/*/api.py`
- `apps/api/` (top-level API gateway)
- `apps/core/throttling.py`
- `app/settings*.py` (REST_FRAMEWORK config)

## Rules

1. Every API endpoint must have explicit `authentication_classes` — never rely solely on global defaults
2. Every API endpoint must have explicit `permission_classes` — `AllowAny` only with justification
3. All mutating endpoints (POST/PUT/PATCH/DELETE) must enforce CSRF or use token-based auth
4. `DEFAULT_RENDERER_CLASSES` must not include `BrowsableAPIRenderer` in production
5. API versioning must be configured — URL prefix `/api/v1/` pattern
6. Error responses must use consistent format: `{"error": "message", "code": "ERROR_CODE"}`
7. Serializer fields must hide sensitive model fields (password, tokens, internal IDs)
8. API pagination must be enforced — never return unbounded querysets
9. CORS must be properly configured — no `CORS_ALLOW_ALL_ORIGINS = True` in production
10. API rate limiting must be configured for all endpoints via DRF throttle classes

## Procedure

1. Enumerate all API views and their security configuration
2. Check authentication classes per endpoint
3. Check permission classes per endpoint
4. Verify throttle classes are applied
5. Check serializer field exposure for sensitive data
6. Verify CORS configuration in settings
7. Check pagination configuration

## Output

API security audit table with endpoint, auth, perms, throttle, CORS status, and risk level.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
