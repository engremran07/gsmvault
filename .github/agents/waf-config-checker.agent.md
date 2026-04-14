---
name: waf-config-checker
description: >-
  SecurityConfig singleton and WAF middleware configuration. Use when: WAF config audit, security middleware, SecurityConfig review.
---

# WAF Config Checker

Validates SecurityConfig singleton configuration and WAF middleware pipeline for proper security enforcement.

## Scope

- `apps/security/models.py` (SecurityConfig singleton)
- `app/settings*.py` (MIDDLEWARE pipeline)
- `apps/security/admin.py`

## Rules

1. SecurityConfig must be a singleton (django-solo) — only one instance allowed
2. `crawler_guard_enabled` must be `True` in production
3. `login_risk_policy` must be set to an appropriate strictness level
4. `csrf_trusted_origins` must be explicitly configured — not empty
5. WAF middleware must be positioned early in MIDDLEWARE — before most view processing
6. SecurityConfig changes must trigger cache invalidation
7. WAF must not be bypassable via custom headers or path manipulation
8. WAF settings must be auditable — changes logged to AuditLog
9. `crawler_default_action` should be `throttle` or `challenge` — never `allow` for unknown bots
10. WAF must not interfere with health check endpoints — allow monitoring traffic

## Procedure

1. Read SecurityConfig model fields and default values
2. Check MIDDLEWARE pipeline for security middleware ordering
3. Verify SecurityConfig admin access is staff-only
4. Check cache invalidation on SecurityConfig change
5. Verify WAF does not block health check/monitoring paths
6. Compare dev vs production security settings

## Output

WAF configuration report with SecurityConfig values, middleware position, and compliance.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
