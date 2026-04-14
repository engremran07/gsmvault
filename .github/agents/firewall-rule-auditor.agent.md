---
name: firewall-rule-auditor
description: >-
  RateLimitRule and BlockedIP configuration auditor. Use when: WAF rule audit, IP block review, rate limit rule check, firewall configuration.
---

# Firewall Rule Auditor

Audits WAF firewall rules including RateLimitRule configuration, BlockedIP entries, and CrawlerRule settings.

## Scope

- `apps/security/models.py` (RateLimitRule, BlockedIP, CrawlerRule, SecurityConfig)
- `apps/security/middleware.py` (if applicable)
- `apps/security/admin.py`

## Rules

1. Login endpoints must have strict rate limits: ≤5 attempts per minute
2. API endpoints must have per-path rate limits configured
3. Upload endpoints must have low rate limits to prevent resource exhaustion
4. BlockedIP entries must have expiry dates — no permanent blocks without review
5. CrawlerRule actions must be one of: `allow`, `throttle`, `block`, `challenge`
6. `crawler_guard_enabled` must be `True` in SecurityConfig for production
7. Rate limit responses must include `Retry-After` header with seconds remaining
8. Rate limit rules must not be so permissive that they are ineffective (e.g., 10000/second)
9. Critical paths (admin, password reset) must have the most restrictive limits
10. Rate limit violations must create SecurityEvent records for monitoring

## Procedure

1. Read all RateLimitRule entries from models/admin
2. Check limits for critical endpoints (login, register, password reset, admin)
3. Read BlockedIP entries and check for permanent blocks without review dates
4. Read CrawlerRule entries and verify action configuration
5. Check SecurityConfig for crawler_guard_enabled
6. Verify SecurityEvent creation on violations

## Output

Firewall rule audit with rule inventory, coverage gaps, and recommendations for missing rules.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
