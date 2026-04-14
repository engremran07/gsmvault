# /security â€” OWASP Security Audit

Perform a full OWASP Top 10 security audit of the codebase (or files given in $ARGUMENTS).

## Scope

If $ARGUMENTS is empty, audit the full `apps/` directory. Otherwise focus on the specified files/apps.

## Audit Checklist (OWASP Top 10 â€” 2021)

### A01: Broken Access Control

- [ ] Every view that returns user-specific data checks `request.user` ownership

- [ ] Admin views check `is_staff` (via `_render_admin` decorator or explicit guard)

- [ ] No IDOR: objects fetched with `.get(pk=pk, user=request.user)` not just `.get(pk=pk)`

- [ ] API endpoints have explicit `permission_classes`; `AllowAny` NOT on mutating endpoints

- [ ] `@login_required` + `@user_passes_test(lambda u: u.is_staff)` on all custom admin views

### A02: Cryptographic Failures

- [ ] No secrets in code (scan for hardcoded keys, passwords, tokens)

- [ ] No `.env` files committed (check `.gitignore`)

- [ ] Private keys not in `storage_credentials/` committed to git

- [ ] HTTPS-only in production settings (`SECURE_SSL_REDIRECT`, `HSTS`)

- [ ] Passwords hashed with Django's default hasher (PBKDF2/Argon2) â€” no MD5/SHA1 for passwords

### A03: Injection

- [ ] No raw SQL: no `cursor.execute()` with user input, no string-formatted queries

- [ ] Django ORM used exclusively for database operations

- [ ] Template rendering: Django auto-escapes HTML; `{% autoescape off %}` only on trusted content

### A04: Insecure Design

- [ ] Scraped data goes through `IngestionJob` â†’ admin approval (never direct DB insert)

- [ ] Download tokens are HMAC-signed and single-use

- [ ] Wallet transactions use `select_for_update()` to prevent race conditions

### A05: Security Misconfiguration

- [ ] `DEBUG = False` in production settings

- [ ] `SECRET_KEY` from environment variable (not hardcoded)

- [ ] `ALLOWED_HOSTS` is explicit (no `["*"]` in production)

- [ ] `X_FRAME_OPTIONS = "DENY"` set

- [ ] CSRF middleware active

### A06: Vulnerable and Outdated Components

- [ ] `pip check` returns no broken deps

- [ ] Check for packages with known CVEs: `pip list --outdated`

- [ ] `requirements.txt` entries have version bounds (not bare package names)

### A07: Authentication and Session Failures

- [ ] MFA available and enforced for admin accounts

- [ ] JWT tokens have short expiry (< 1 hour for access tokens)

- [ ] Session cookies: `SESSION_COOKIE_SECURE = True` in production

- [ ] Failed login attempts rate-limited via `apps.security`

### A08: Software and Data Integrity Failures

- [ ] CDN resources have integrity hash (SRI) or local vendor fallbacks

- [ ] No `eval()`, `exec()`, or `importlib.import_module()` with user-controlled input

### A09: Logging and Monitoring Failures

- [ ] Security events logged to `apps.security.SecurityEvent`

- [ ] No sensitive data in logs (passwords, tokens, PII)

- [ ] Failed auth attempts logged

### A10: Server-Side Request Forgery (SSRF)

- [ ] URL fetching (scraper, webhooks) validates against an allowlist

- [ ] No user-supplied URLs passed directly to `requests.get()` without validation

- [ ] Webhook delivery validates the target URL format

## Output Format

Report findings by severity:
- **CRITICAL**: Exploitable vulnerability, fix immediately
- **HIGH**: Significant risk, fix before next deployment
- **MEDIUM**: Should fix, lower exploit probability
- **LOW**: Defence in depth improvement
- **INFO**: Observation, no immediate action needed

For each finding: file path + line number + description + recommended fix.
