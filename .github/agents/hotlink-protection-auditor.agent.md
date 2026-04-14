---
name: hotlink-protection-auditor
description: >-
  HotlinkBlock configuration and referrer validation. Use when: hotlink protection audit, referrer check, direct link prevention.
---

# Hotlink Protection Auditor

Audits hotlink protection configuration for firmware downloads, verifying referrer validation and domain allowlisting.

## Scope

- `apps/firmwares/models.py` (HotlinkBlock)
- `apps/firmwares/download_service.py`
- `apps/firmwares/views.py`

## Rules

1. Hotlink protection must be enabled for all firmware download endpoints
2. `check_hotlink_protection()` must validate HTTP Referer header against allowed domains
3. HotlinkBlock entries must cover known hotlinking domains
4. Missing Referer header should be handled configurable — block or allow based on setting
5. Referer validation must be case-insensitive and handle URL variations (www vs non-www)
6. Empty Referer must be allowed for direct browser navigation (bookmarks, typed URLs)
7. Allowed domains must include the platform's own domain and legitimate partners
8. Hotlink attempts must be logged for monitoring
9. Blocked hotlink requests must return HTTP 403 with explanatory message
10. Hotlink protection must not break legitimate embedded links from allowed partners

## Procedure

1. Read HotlinkBlock model and entries
2. Verify `check_hotlink_protection()` implementation
3. Check download views for hotlink check enforcement
4. Verify allowed domain configuration
5. Check logging of hotlink attempts
6. Test edge cases: missing Referer, empty Referer, partial domain match

## Output

Hotlink protection report with configured domains, enforcement status, and coverage gaps.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
