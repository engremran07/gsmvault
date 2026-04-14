---
name: api-throttle-checker
description: >-
  Checks DRF throttle class configuration. Use when: throttle audit, missing throttle classes, rate config review, throttle scope check.
---

# API Throttle Checker

Verifies DRF throttle class configuration across all API endpoints, ensuring proper rate limiting is in place.

## Scope

- `apps/core/throttling.py`
- `apps/*/api.py`
- `app/settings*.py` (REST_FRAMEWORK config)

## Rules

1. `DEFAULT_THROTTLE_CLASSES` must be set in REST_FRAMEWORK settings
2. `DEFAULT_THROTTLE_RATES` must define rates for all scopes used
3. Upload endpoints must use `UploadRateThrottle` from `apps.core.throttling`
4. Download endpoints must use `DownloadRateThrottle`
5. General API endpoints must use `APIRateThrottle`
6. Anonymous requests must have stricter limits than authenticated requests
7. Throttle rate format must be valid: `"number/period"` (e.g., `"100/hour"`)
8. ViewSets overriding throttle_classes must not weaken global defaults
9. Custom throttle scopes must be registered in settings
10. Throttle classes must return proper 429 response with `Retry-After` header

## Procedure

1. Parse REST_FRAMEWORK settings for throttle configuration
2. Enumerate all API views and extract throttle_classes
3. Check for endpoints with no throttle configuration
4. Verify throttle rates are reasonable (not too permissive)
5. Check custom throttle scope registration
6. Verify 429 response format

## Output

Throttle configuration report with endpoint, classes, rates, and gaps.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
