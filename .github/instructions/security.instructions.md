---
applyTo: 'apps/security/**, apps/*/views.py'
---

# Security Instructions

## Two Separate Rate-Limiting Systems — NEVER Conflate

| System | Location | Purpose |
|---|---|---|
| **WAF rate limits** | `apps.security` (`RateLimitRule`, `BlockedIP`, `CrawlerRule`) | IP/path-based DDoS/bot protection at middleware level |
| **Download quotas** | `apps.firmwares` (`DownloadToken`) + `apps.devices` (`QuotaTier`) | Per-user/tier download limits at firmware download time |

**FORBIDDEN**: Importing `RateLimitRule` in firmware code. Importing `DownloadToken` in security code. These systems are completely independent.

## WAF Security Models (`apps.security`)

| Model | Purpose |
|---|---|
| `SecurityConfig` | Singleton: MFA policy, crawler guard toggle, login risk policy |
| `SecurityEvent` | Audit log (login_fail, mfa_fail, rate_limited, ip_blocked) |
| `RateLimitRule` | Per-path rules (limit, window, action: throttle/block/log) |
| `BlockedIP` | Permanent or timed IP blocks |
| `CSPViolationReport` | Content-Security-Policy violation reports |
| `CrawlerRule` | Bot/crawler path rules (requests_per_minute, action) |
| `CrawlerEvent` | Log of every matched crawler request |

## Input Sanitization — MANDATORY

All user-supplied HTML content MUST be sanitized:

```python
from apps.core.sanitizers import sanitize_html_content

clean_content = sanitize_html_content(user_input)
```

- **Always use `nh3`** (Rust-based) via `apps.core.sanitizers`
- **Never use `bleach`** — it is deprecated and has been replaced by `nh3`
- Sanitize BEFORE saving to database (stored XSS prevention)
- Use `sanitize_ad_code()` for ad HTML that needs script/iframe tags

## CSRF Protection — MANDATORY

- CSRF on ALL mutating endpoints (POST, PUT, PATCH, DELETE)
- Global HTMX CSRF via `<body hx-headers='{"X-CSRFToken": "..."}'>` in `base.html`
- Never use `@csrf_exempt` without explicit security review and documentation
- AJAX calls: include `X-CSRFToken` header from `getCookie('csrftoken')`

## Authentication Checks

```python
# Safe pattern for views where user may be anonymous
if getattr(request.user, "is_staff", False):
    # Staff-only logic

# Ownership check — ALWAYS verify
obj = MyModel.objects.get(pk=pk, user=request.user)  # Not just .get(pk=pk)
```

- Always use `getattr(request.user, "is_staff", False)` — not `request.user.is_staff`
- Never trust user-supplied IDs without ownership check
- Admin views MUST check `@login_required` + `@user_passes_test(lambda u: u.is_staff)`

## Security Headers

- `X_FRAME_OPTIONS = "DENY"` — clickjacking protection
- CSP nonce on all inline scripts in production (via `csp_nonce` middleware)
- `SECURE_SSL_REDIRECT = True` in production
- HSTS headers enabled in production settings
- `X-Content-Type-Options: nosniff` — prevent MIME type sniffing

## Secrets Management

- **No secrets in source code** — all via environment variables (`.env` files, never committed)
- Service account JSON in `storage_credentials/` (gitignored)
- Never log sensitive data (passwords, tokens, full request bodies with credentials)
- Never expose stack traces or internal error details to end users

## Database Safety

- **No raw SQL** — Django ORM exclusively
- Parameterized queries enforced by the ORM — never format user data into query strings
- Always `select_for_update()` on financial/wallet record mutations
- All multi-model service operations: `@transaction.atomic`

## File Upload Validation

Validate ALL file uploads in the service layer:

```python
def validate_upload(file):
    # 1. Check file size
    if file.size > MAX_UPLOAD_SIZE:
        raise ValidationError("File too large")
    # 2. Check MIME type
    mime = magic.from_buffer(file.read(1024), mime=True)
    file.seek(0)
    if mime not in ALLOWED_MIME_TYPES:
        raise ValidationError("Invalid file type")
    # 3. Check extension
    ext = os.path.splitext(file.name)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise ValidationError("Invalid extension")
```

## View Security Checklist

For every new view, verify:
1. Authentication required? → `@login_required` or `LoginRequiredMixin`
2. Staff-only? → `@user_passes_test(lambda u: u.is_staff)`
3. Object ownership? → Filter queryset by `user=request.user`
4. CSRF? → Automatically applied (don't exempt)
5. Input sanitized? → `sanitize_html_content()` on any HTML input
6. Rate limited? → DRF throttle class or WAF rule
