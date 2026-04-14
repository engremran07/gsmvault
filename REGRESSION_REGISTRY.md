# Regression Registry

Tracks every confirmed regression and its guard. Adapted from AcTechs + Footwear governance patterns.

## Format

- **ID**: `RR-NNN` sequential identifier
- **Status**: `OPEN` (unguarded regression) or `CLOSED` (guard in place, verified)
- **Date**: Date the regression was identified (YYYY-MM-DD)
- **Category**: Security | Frontend | Architecture | Quality | Database | Performance
- **Description**: Brief description of the regression
- **Guard**: File:line reference to the code that prevents recurrence
- **Root Cause**: Why the regression happened

## Registry

| ID | Status | Date | Category | Description | Guard | Root Cause |
| ---- | -------- | ------ | ---------- | ------------- | ------- | ------------ |
| RR-001 | CLOSED | 2025-12-01 | Security | XSS in blog post body — raw HTML stored without sanitization | `apps/blog/models.py:Post.save()` calls `sanitize_html()` | Missing sanitizer call on model save |
| RR-002 | CLOSED | 2025-12-01 | Security | Bleach dependency deprecated — replaced by nh3 | `apps/core/sanitizers.py` uses `nh3.clean()` | Bleach unmaintained since 2023 |
| RR-003 | CLOSED | 2026-04-14 | Security | Pages app stored raw HTML without sanitization | `apps/pages/models.py:Page.save()` calls `sanitize_html_content()` | No sanitizer call on Page model save |
| RR-004 | CLOSED | 2026-04-14 | Frontend | HTMX requests from expired sessions injected login page HTML | `app/middleware/htmx_auth.py:HtmxAuthExpiryMiddleware` returns HX-Redirect | No HTMX-aware auth expiry handling |

## Rules

1. **NEVER** close an entry without verifying the guard is in place AND tests pass
2. **ALWAYS** link to the specific file + line where the guard lives
3. A "guard" is the specific code that prevents the regression from recurring
4. If a guard is removed and the regression recurs, re-open with `RECURRED` note
5. Every OPEN entry blocks deployment until resolved
