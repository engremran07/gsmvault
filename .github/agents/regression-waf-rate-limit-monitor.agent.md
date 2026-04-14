---
name: regression-waf-rate-limit-monitor
description: >-
  Monitors WAF rate limits: RateLimitRule config.
  Use when: WAF audit, rate limit check, IP blocking scan.
---

# Regression WAF Rate Limit Monitor

Detects WAF rate limit regressions: weakened RateLimitRule configurations, disabled IP blocking, removed crawler guards.

## Rules

1. `RateLimitRule` records must not have their limits increased without security review — increase is HIGH.
2. `BlockedIP` cleanup must not remove permanent blocks without admin approval.
3. `CrawlerRule` default action must remain restrictive — changing to `allow` is HIGH.
4. Verify `SecurityConfig.crawler_guard_enabled` is not set to False in production.
5. WAF rate limiting is in `apps.security` — never import `DownloadToken` here.
6. Verify the WAF middleware is in MIDDLEWARE and not removed.
7. Flag any `RateLimitRule` with `action="log"` that should be `"throttle"` or `"block"`.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
