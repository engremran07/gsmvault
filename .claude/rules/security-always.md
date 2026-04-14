---
# No applies_to — these rules are ALWAYS active, regardless of file type.
---

# Security Rules — Always Active

These security rules apply everywhere, every time. They cannot be overridden by context.

## System Boundary: WAF vs Download Quotas

The platform has **two separate, non-overlapping rate-limiting systems**:

| System | Location | Purpose |
|--------|----------|---------|
| **WAF rate limits** | `apps.security` (`RateLimitRule`, `BlockedIP`, `CrawlerRule`) | IP/path-based DDoS/bot protection at the middleware level |
| **Download quotas** | `apps.firmwares` (`DownloadToken`) + `apps.devices` (`QuotaTier`) | Per-user/tier download limits at firmware download time |

**FORBIDDEN**: Importing `RateLimitRule` in firmware code. Importing `DownloadToken` in security code. Conflating the two systems in any way.

## Scraper Approval Workflow

All OEM-scraped firmware data MUST go through the admin approval workflow. Scraped items:
1. Are created as `IngestionJob` records with `status = "pending"`.
2. Require explicit admin approval before processing.
3. **NEVER auto-insert** into the database without approval.

Never bypass this by writing scraped data directly to `Firmware` or related models.

## Input Validation

- All user-supplied HTML content MUST be sanitized with `apps.core.sanitizers.sanitize_html_content()` (nh3-based, OWASP XSS safe).
- Never use `bleach` — it has been replaced by `nh3`. See `nh3-sanitizer-gotcha` repo memory.
- All user inputs in forms must be validated through Django form/serializer validation.
- File uploads: validate MIME type, extension, and file size in the service layer before storage.

## Authentication Checks

- Always use `getattr(request.user, "is_staff", False)` pattern (not `request.user.is_staff`) in views where the user object may be anonymous.
- Never trust user-supplied IDs without an ownership check: `.get(pk=pk, user=request.user)`.
- Admin views MUST check `@login_required` + `@user_passes_test(lambda u: u.is_staff)` (or use the `_render_admin` decorator which enforces this).

## Database Safety

- No raw SQL anywhere in application code. Django ORM only.
- Parameterized queries are enforced by the ORM — never format user data into query strings.
- Always `select_for_update()` on financial/wallet record mutations.
- All model operations that span multiple tables: `@transaction.atomic`.

## Secrets and Credentials

- No secrets, API keys, tokens, or passwords in source code.
- All credentials via environment variables (`.env` files, never committed).
- Service account JSON files live in `storage_credentials/` (gitignored).
- Never log sensitive data (passwords, tokens, full request bodies with credentials).

## App Boundary Enforcement

Cross-app model imports in `models.py` or `services.py` are strictly forbidden (except the allowed patterns):
- Allowed everywhere: `apps.core.*`, `apps.site_settings.*`, `settings.AUTH_USER_MODEL`
- Allowed in `apps/admin/` only: all other apps' models
- Allowed in views: models from multiple apps (views are orchestrators)
- **Forbidden in models.py / services.py**: direct imports of another app's models

Cross-app communication: use `apps.core.events.EventBus` or Django signals.

## Security Headers

- `X_FRAME_OPTIONS = "DENY"` — clickjacking protection.
- CSP nonce on all inline scripts in production.
- HTTPS-only in production (`SECURE_SSL_REDIRECT = True`, `HSTS` headers).
- CSRF protection on ALL mutating view endpoints.
