---
name: regression-consent-redirect-monitor
description: >-
  Monitors consent views: JSON responses (forbidden).
  Use when: consent audit, consent view check, redirect pattern scan.
---

# Regression Consent Redirect Monitor

Detects consent view regressions: returning JSON instead of HttpResponseRedirect. Consent form views must ALWAYS redirect.

## Rules

1. `accept_all`, `reject_all`, and `accept` views must return `HttpResponseRedirect` — JSON response is CRITICAL.
2. The redirect target must be `HTTP_REFERER` — hardcoded URLs are HIGH.
3. The consent cookie must be set on the redirect response, not before.
4. For JSON consent API, only `consent/api/status/` and `consent/api/update/` endpoints may return JSON.
5. Verify the `_consent_done()` helper pattern is used consistently across all consent form views.
6. Flag any `JsonResponse` or `Response` return in consent form views.
7. Verify `fetch()` callers follow the redirect automatically.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
