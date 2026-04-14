---
name: clickjacking-checker
description: >-
  X-Frame-Options and frame-ancestors CSP validation. Use when: clickjacking prevention, iframe embedding, frame-ancestors audit.
---

# Clickjacking Checker

Validates clickjacking protection via X-Frame-Options header and Content-Security-Policy frame-ancestors directive.

## Scope

- `app/settings*.py`
- `app/middleware/csp_nonce.py`
- `apps/security/models.py` (CSPViolationReport)

## Rules

1. `X_FRAME_OPTIONS = "DENY"` must be set in settings — prevents all iframe embedding
2. CSP `frame-ancestors` directive must be `'none'` or `'self'` in production
3. If specific pages need iframe embedding (widgets, embeds), use per-view `@xframe_options_sameorigin`
4. Never use `@xframe_options_exempt` without security review and documentation
5. Both X-Frame-Options and CSP frame-ancestors should be set for browser compatibility
6. X-Frame-Options middleware (`XFrameOptionsMiddleware`) must be in MIDDLEWARE pipeline
7. CSP frame-ancestors takes precedence in modern browsers — keep both for backward compatibility
8. Third-party embed widgets must use postMessage API instead of iframes where possible
9. admin pages must never be embeddable — additional DENY enforcement
10. CSP violation reports for frame-ancestors violations must be monitored

## Procedure

1. Check X_FRAME_OPTIONS setting in all settings files
2. Verify XFrameOptionsMiddleware is in MIDDLEWARE
3. Check CSP frame-ancestors directive
4. Search for `@xframe_options_exempt` or `@xframe_options_sameorigin` usage
5. Verify admin pages have DENY enforcement
6. Check CSP violation report monitoring

## Output

Clickjacking protection report with header configuration and per-view exceptions.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
