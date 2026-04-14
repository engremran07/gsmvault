---
name: download-security-auditor
description: >-
  Download endpoint security auditor. Use when: download token validation, hotlink protection, download gating, firmware download security.
---

# Download Security Auditor

Audits firmware download endpoint security including token validation, hotlink protection, ad-gate enforcement, and download session tracking.

## Scope

- `apps/firmwares/download_service.py`
- `apps/firmwares/views.py` (download views)
- `apps/firmwares/models.py` (DownloadToken, DownloadSession, AdGateLog, HotlinkBlock)
- `apps/devices/models.py` (QuotaTier)

## Rules

1. Every firmware download must require a valid `DownloadToken` — no direct file URLs
2. DownloadToken must be HMAC-signed and time-limited with configurable expiry
3. Token status must transition: `active` → `used` — tokens are single-use
4. Ad-gate verification must complete before download is allowed (for free-tier users)
5. Hotlink protection must validate HTTP Referer against allowed domains
6. Download sessions must track bytes delivered for bandwidth monitoring
7. Expired/revoked tokens must return HTTP 410 Gone, not 404
8. Download quota checks must happen BEFORE token generation, not after
9. File serving must use `X-Sendfile` or streaming response — never read entire file into memory
10. Download URLs must not be predictable — use cryptographic tokens, not sequential IDs

## Procedure

1. Trace the complete download flow from request to file delivery
2. Verify DownloadToken creation includes HMAC signature
3. Check token validation on download endpoint
4. Verify hotlink protection is active
5. Check ad-gate enforcement for free-tier users
6. Verify download session creation and completion tracking
7. Check quota enforcement before token creation

## Output

Download security audit with flow diagram, validation checks, and gap analysis.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
