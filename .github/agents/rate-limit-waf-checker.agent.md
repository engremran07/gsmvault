---
name: rate-limit-waf-checker
description: >-
  WAF rate limit checker. Use when: RateLimitRule configuration, BlockedIP rules, crawler guard, WAF middleware audit.
---

# WAF Rate Limit Checker

Validates WAF-level rate limiting configuration in `apps.security` including RateLimitRule entries, BlockedIP management, and CrawlerRule configuration.

## Scope

- `apps/security/models.py`
- `apps/security/middleware.py` (if exists)
- `apps/security/admin.py`
- `app/middleware/*.py`

## Rules

1. RateLimitRule must cover critical paths: `/login/`, `/register/`, `/api/`, `/admin/`
2. Each rule must have a reasonable `window_seconds` (not too large, not too small)
3. Actions must be appropriate: `throttle` for soft limits, `block` for hard limits, `log` for monitoring
4. BlockedIP entries must have `expires_at` set — no indefinite blocks without admin flag
5. CrawlerRule must be configured for known aggressive bots
6. SecurityConfig singleton must have `crawler_guard_enabled` set appropriately
7. Rate limit bypass must not be achievable via header spoofing (X-Forwarded-For)
8. WAF must log SecurityEvent on every rate limit trigger
9. Admin must be able to view and manage all active blocks
10. IP-based limits must handle IPv6 and proxy chains correctly

## Procedure

1. Read SecurityConfig singleton settings
2. Enumerate all RateLimitRule entries and their coverage
3. Check BlockedIP entries for missing expiry
4. Verify CrawlerRule configuration
5. Check middleware pipeline for WAF enforcement order
6. Verify logging of rate limit events

## Output

WAF configuration report with rule coverage gaps and misconfiguration warnings.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
