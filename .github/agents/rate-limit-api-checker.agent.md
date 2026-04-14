---
name: rate-limit-api-checker
description: >-
  API rate limit checker. Use when: DRF throttle classes, per-user limits, per-IP limits, API throttle configuration audit.
---

# API Rate Limit Checker

Verifies DRF throttle class configuration on all API endpoints, including per-user, per-IP, and custom throttle scopes.

## Scope

- `apps/core/throttling.py`
- `apps/*/api.py`
- `app/settings*.py` (REST_FRAMEWORK throttle config)

## Rules

1. All API ViewSets must have `throttle_classes` defined or inherit from global defaults
2. `apps.core.throttling` provides 6 DRF classes — use them, don't create per-app throttle classes
3. Upload endpoints must use `UploadRateThrottle` — more restrictive than general API throttle
4. Download endpoints must use `DownloadRateThrottle` with tier-based limits
5. Anonymous API access must have stricter throttle limits than authenticated access
6. `DEFAULT_THROTTLE_RATES` must be configured in REST_FRAMEWORK settings
7. Custom throttle scopes must be documented and registered
8. Throttle responses must return HTTP 429 with `Retry-After` header
9. Throttle classes must not be disabled in development settings
10. Burst-style throttle rates (e.g., `10/second`) must pair with sustained rates (e.g., `100/hour`)

## Procedure

1. Read REST_FRAMEWORK settings for DEFAULT_THROTTLE_CLASSES and DEFAULT_THROTTLE_RATES
2. Enumerate all API views and check for explicit throttle_classes
3. Verify throttle class imports come from `apps.core.throttling`
4. Check for endpoints missing throttle configuration
5. Verify throttle rate strings are properly formatted

## Output

API throttle coverage report listing endpoints, throttle classes, and rate limits.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
