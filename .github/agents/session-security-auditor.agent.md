---
name: session-security-auditor
description: >-
  Session security auditor. Use when: session configuration, session stores, session middleware, session fixation prevention.
---

# Session Security Auditor

Comprehensive session security audit covering configuration, storage backend, middleware pipeline, and session lifecycle management.

## Scope

- `app/settings*.py`
- `app/middleware/*.py`
- `apps/users/views.py` (login/logout)
- `apps/security/models.py` (SecurityConfig)

## Rules

1. Session backend must be database or Redis — never signed-cookie for authenticated sessions
2. Session middleware must be in the correct position in MIDDLEWARE pipeline (after SecurityMiddleware, before AuthenticationMiddleware)
3. Session fixation: session ID must rotate on every authentication state change (login, logout, privilege escalation)
4. Session timeout must be configured: both idle timeout and absolute timeout
5. Concurrent session management: decide policy (allow multiple, limit, invalidate old)
6. Session data must not contain serialized objects that could enable deserialization attacks
7. Session flush on logout must clear all session data, not just the session key
8. Session store must handle expiration cleanup — stale sessions must be purged periodically
9. Session cookie name should not reveal framework (`sessionid` is fine, but custom names are better)
10. Session-related SecurityEvents must be logged: creation, destruction, fixation attempts

## Procedure

1. Read all session-related settings across all settings files
2. Verify middleware pipeline ordering
3. Check login/logout views for session management
4. Verify session cleanup tasks exist
5. Check for session data that may contain sensitive information
6. Review concurrent session handling

## Output

Session security audit report with configuration, compliance status, and remediation steps.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
