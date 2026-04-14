# /test-security â€” Run security-focused tests

Execute security-oriented tests across the platform: CSRF protection, XSS prevention, authentication guards, permission enforcement, and input validation.

## Scope

$ARGUMENTS

## Checklist

### Step 1: CSRF Protection

- [ ] Verify `{% csrf_token %}` in all forms across `templates/`

- [ ] Confirm global HTMX CSRF header in `<body hx-headers>` in `templates/base/base.html`

- [ ] Grep for `@csrf_exempt` â€” each must have documented justification

- [ ] Test POST endpoints reject requests without CSRF token

### Step 2: XSS Prevention

- [ ] Grep for `|safe` in templates â€” each must have upstream `sanitize_html_content()` call

- [ ] Verify `apps.core.sanitizers.sanitize_html_content()` (nh3-based) is used, NOT bleach

- [ ] Check all user-supplied HTML fields pass through sanitization in services layer

- [ ] Scan for `mark_safe()` usage â€” must be on trusted content only

### Step 3: Authentication Checks

- [ ] Verify all protected views have `@login_required` or equivalent

- [ ] Verify admin views use `@user_passes_test(lambda u: u.is_staff)` or `_render_admin` decorator

- [ ] Check `getattr(request.user, "is_staff", False)` pattern (not direct `.is_staff`)

- [ ] Verify ownership checks: `.get(pk=pk, user=request.user)` on user-scoped resources

### Step 4: Input Validation

- [ ] Verify file uploads validate MIME type, extension, and size in service layer

- [ ] Confirm Django form/serializer validation on all user inputs

- [ ] Check no raw SQL anywhere â€” Django ORM exclusively

- [ ] Verify parameterized queries (ORM enforced)

### Step 5: Security Headers

- [ ] Confirm `X_FRAME_OPTIONS = "DENY"` in settings

- [ ] Verify CSP nonce middleware in `app/middleware/csp_nonce.py`

- [ ] Check HTTPS-only settings in production (`SECURE_SSL_REDIRECT`, HSTS)

### Step 6: Secrets Scan

- [ ] Grep for hardcoded API keys, tokens, passwords in source code

- [ ] Verify `.env` files are in `.gitignore`

- [ ] Verify `storage_credentials/` is gitignored

- [ ] Check no sensitive data in logs

### Step 7: Run Security Tests

- [ ] Run `& .\.venv\Scripts\python.exe -m pytest -k "security or csrf or xss or auth" --tb=short`

- [ ] Report pass/fail counts and any failures
