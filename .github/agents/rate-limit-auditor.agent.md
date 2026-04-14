---
name: rate-limit-auditor
description: >-
  Rate limiting auditor across both systems. Use when: WAF rules, API throttles, download quotas, rate limit configuration review.
---

# Rate Limit Auditor

Audits both rate limiting systems: WAF/security rate limiting (`apps.security`) and download quota system (`apps.firmwares` + `apps.devices`). Ensures they are properly configured and not conflated.

## Scope

- `apps/security/models.py` (RateLimitRule, BlockedIP)
- `apps/firmwares/models.py` (DownloadToken, DownloadSession)
- `apps/devices/models.py` (QuotaTier)
- `apps/core/throttling.py`
- `app/settings*.py`

## Rules

1. WAF rate limits (`apps.security`) and download quotas (`apps.firmwares` + `apps.devices`) are TWO SEPARATE SYSTEMS — never conflate them
2. Never import `RateLimitRule` in firmware code or `DownloadToken` in security code
3. All public-facing endpoints must have rate limiting configured — either WAF-level or DRF throttle
4. Login endpoints must have aggressive rate limiting (max 5 attempts per minute)
5. API endpoints must use DRF throttle classes from `apps.core.throttling`
6. Download quota enforcement must happen at download time via `DownloadToken` validation
7. Rate limit responses must include `Retry-After` header
8. Blocked IPs must have expiry — no permanent blocks without admin review
9. Rate limit rules must cover all HTTP methods, not just GET
10. Rate limiting must be tested under load to verify it actually blocks excess requests

## Procedure

1. Enumerate all RateLimitRule records and their path coverage
2. Check DRF throttle class configuration in settings
3. Verify download quota enforcement in firmware download views
4. Identify endpoints without any rate limiting
5. Check for proper separation between WAF and download quota systems
6. Verify rate limit headers in responses

## Output

Rate limit coverage matrix showing endpoints, limiting mechanism, and configuration values.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
