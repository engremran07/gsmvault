---
name: consent-enforcement-auditor
description: >-
  Consent enforcement auditor. Use when: consent decorator, consent middleware, GDPR compliance, consent flow audit.
---

# Consent Enforcement Auditor

Audits consent enforcement across the platform including `@consent_required` decorator usage, middleware configuration, and consent scope compliance.

## Scope

- `apps/consent/decorators.py`
- `apps/consent/middleware.py`
- `apps/consent/views.py`
- `apps/*/views.py` (views requiring consent)
- `templates/**/*.html` (consent-gated content)

## Rules

1. Analytics tracking must be gated behind `analytics` consent scope
2. SEO tracking must be gated behind `seo` consent scope
3. Ad personalization must be gated behind `ads` consent scope
4. `functional` consent scope is always required — cannot be declined
5. Consent form views NEVER return JSON — always `HttpResponseRedirect` to `HTTP_REFERER`
6. Consent cookie must be set on the redirect response, not in a JSON body
7. `@consent_required` decorator must be applied to views that process personal data
8. Consent middleware must be in the MIDDLEWARE pipeline at the correct position
9. Third-party scripts (analytics, ads) must check consent before loading
10. Consent status must be re-verified on every request that processes personal data — not cached

## Procedure

1. Check consent middleware is in MIDDLEWARE pipeline
2. Enumerate views that process personal data and verify `@consent_required`
3. Check template consent gates for analytics/ads/SEO scripts
4. Verify consent cookie configuration
5. Check consent view response patterns (redirect, not JSON)
6. Verify consent API endpoints for JSON access

## Output

Consent enforcement report with scope coverage, missing decorators, and compliance gaps.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
