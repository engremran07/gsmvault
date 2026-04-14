---
agent: 'agent'
description: 'Run an OWASP Top 10 security audit across the entire codebase'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal', 'get_errors']
---

# OWASP Top 10 Security Audit

Perform a comprehensive security audit of the GSMFWs platform against the OWASP Top 10 (2021). Report every finding with severity, file location, and remediation steps.

## A01:2021 — Broken Access Control

1. **Missing Auth Guards** — Scan all views in `apps/*/views*.py` for functions/classes missing `@login_required`, `LoginRequiredMixin`, or equivalent. Every non-public view must enforce authentication.

2. **Missing Ownership Checks** — Views that access user-specific data must filter by `user=request.user` or equivalent. Grep for `.get(pk=` or `.filter(pk=` without ownership constraint.

3. **Staff Bypass** — Staff-only views must use `@user_passes_test(lambda u: u.is_staff)` or the `_render_admin` decorator. Grep for `is_staff` checks that use bare attribute access instead of `getattr(request.user, "is_staff", False)`.

4. **CORS Configuration** — Check `app/settings*.py` for `CORS_ALLOWED_ORIGINS`. Verify not set to `CORS_ALLOW_ALL_ORIGINS = True` in production.

5. **X-Frame-Options** — Verify `X_FRAME_OPTIONS = "DENY"` in settings.

## A02:2021 — Cryptographic Failures

1. **HTTPS Enforcement** — Check production settings for `SECURE_SSL_REDIRECT = True`, `SECURE_HSTS_SECONDS`, `SECURE_HSTS_INCLUDE_SUBDOMAINS`.

2. **Secure Cookies** — Verify `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, `SESSION_COOKIE_HTTPONLY` in production settings.

3. **Password Hashing** — Check `PASSWORD_HASHERS` in settings. Argon2 or bcrypt should be first.

4. **Secret Key** — Verify `SECRET_KEY` loads from environment variable, not hardcoded.

5. **Token Security** — Check JWT configuration uses secure algorithms (HS256 minimum). Verify short token expiry.

## A03:2021 — Injection

1. **SQL Injection** — Grep entire `apps/` directory for `raw(`, `.extra(`, `RawSQL(`, `.cursor().execute(`, `connection.cursor()`. Zero tolerance — Django ORM exclusively.

2. **XSS — Stored** — All user-input HTML fields must pass through `apps.core.sanitizers.sanitize_html_content()` before storage. Grep `apps/*/models.py` and `apps/*/services*.py` for fields accepting HTML without sanitization.

3. **XSS — Reflected** — Grep templates for `{{ request.GET.` or `{{ request.POST.` rendered without escaping. Django auto-escapes but check for `|safe` usage.

4. **XSS — Template Safe Filter** — Grep all `templates/**/*.html` for `|safe`. Each usage must trace back to data that has been nh3-sanitized. Flag any `|safe` on user-controlled data.

5. **Command Injection** — Grep for `os.system(`, `subprocess.call(`, `subprocess.Popen(` with user-supplied arguments.

## A04:2021 — Insecure Design

1. **Scraper Approval** — Verify scraped data goes through `IngestionJob` with `status=pending` → admin approval. Grep for direct writes to `Firmware` model from scraper code.

2. **Download Quota Enforcement** — Verify `apps/firmwares/download_service.py` checks `QuotaTier` limits before creating `DownloadToken`.

3. **Rate Limit Separation** — Verify WAF rate limits (`apps.security`) and download quotas (`apps.firmwares` + `apps.devices`) are never conflated. Grep for `RateLimitRule` imported in firmware code or `DownloadToken` in security code.

## A05:2021 — Security Misconfiguration

1. **Debug Mode** — Verify `DEBUG = False` in `app/settings_production.py`.

2. **Allowed Hosts** — Check `ALLOWED_HOSTS` is not `["*"]` in production.

3. **Admin URL** — Check if admin URL is at a non-default path (not `/admin/`).

4. **Error Details** — Verify production error pages don't leak stack traces. Check `apps.core.exceptions.json_error_response()` hides details when `DEBUG=False`.

5. **CSP Headers** — Verify `app/middleware/csp_nonce.py` is in `MIDDLEWARE` and generates nonces for inline scripts.

## A06:2021 — Vulnerable Components

1. **Dependency Check** — Run `& .\.venv\Scripts\pip.exe check` for broken dependency chains.

2. **Known CVEs** — Run `& .\.venv\Scripts\pip.exe list --outdated --format=columns` and flag packages with known vulnerabilities.

3. **CDN Versions** — Check `templates/base/base.html` for pinned CDN library versions (Tailwind, Alpine, HTMX, Lucide).

## A07:2021 — Authentication Failures

1. **Brute Force Protection** — Verify login rate limiting exists via `apps.security.RateLimitRule` for login paths.

2. **MFA Configuration** — Check `apps.users` for MFA implementation. Verify staff users require MFA.

3. **Session Fixation** — Verify Django's default session rotation on login is active (not overridden).

4. **Password Policy** — Check `AUTH_PASSWORD_VALIDATORS` in settings for minimum length, common password check, numeric-only prevention.

## A08:2021 — Data Integrity Failures

1. **CSRF Protection** — Verify `CsrfViewMiddleware` is in `MIDDLEWARE`. Grep for `@csrf_exempt` — each must be justified.

2. **CSRF in HTMX** — Verify global CSRF header injection via `<body hx-headers='{"X-CSRFToken": ...}'>` in `base.html`.

3. **Webhook Signatures** — Check `apps/notifications` webhook delivery includes HMAC signature verification.

## A09:2021 — Logging & Monitoring

1. **Security Event Logging** — Verify `apps.security.SecurityEvent` records login failures, rate limit hits, IP blocks.

2. **Audit Trail** — Check `apps.admin.AuditLog` records admin actions with field-level change tracking.

3. **No Sensitive Logging** — Grep for `logger.` or `print(` calls that might log passwords, tokens, or full request bodies with credentials.

## A10:2021 — SSRF

1. **Outbound Requests** — Grep for `requests.get(`, `requests.post(`, `httpx.`, `urllib` with user-supplied URLs. Verify URL allowlisting.

2. **Webhook URLs** — Check `WebhookEndpoint` URL validation prevents internal network access.

## Report Format

```
[CRITICAL/HIGH/MEDIUM/LOW] A0X — Finding Title
  Location: apps/module/file.py:LINE
  Evidence: code snippet showing the vulnerability
  Impact: what an attacker could achieve
  Fix: specific remediation step
```

## Summary

Produce final counts per OWASP category and overall security posture score (0-100).
