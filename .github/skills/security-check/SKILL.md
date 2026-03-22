---
name: security-check
description: "Run security audit on Django codebase. Use when: checking for OWASP vulnerabilities, auditing authentication, reviewing CSRF protection, scanning for secrets, validating security headers, running bandit."
---

# Security Check

## When to Use
- Pre-deployment security review
- After adding new endpoints or authentication logic
- After adding file upload handling or user-controlled URL fetching
- Periodic security audit of any app in the 30-app platform

## Procedure

### Step 1: Static Analysis
```powershell
& .\.venv\Scripts\python.exe -m bandit -r apps/ -ll -ii --exclude "*/tests*,*/migrations/*"
```

### Step 2: Django Check (deploy mode)
```powershell
& .\.venv\Scripts\python.exe manage.py check --deploy --settings=app.settings_production
```

### Step 3: Manual Review Checklist

#### Authentication & Authorization
- [ ] All mutating endpoints have `permission_classes` set (no default open access)
- [ ] `IsAuthenticated` or stricter on every ViewSet
- [ ] Admin views (`apps/admin/views_*.py`) check `request.user.is_staff`
- [ ] JWT `ACCESS_TOKEN_LIFETIME` configured in `SIMPLE_JWT` settings
- [ ] No `AllowAny` on endpoints that write data

#### Input Validation
- [ ] All user input passes through DRF serializers before reaching ORM
- [ ] File uploads validated: extension checked against `SecurityConfig.allowed_upload_extensions`, size against `max_upload_size_mb`
- [ ] No raw SQL — Django ORM only
- [ ] URL parameters validated before use in queryset filters
- [ ] Webhook URL targets validated against an allowlist (no SSRF)

#### Security Headers (settings_production.py)
- [ ] `SECURE_HSTS_SECONDS >= 31536000`
- [ ] `X_FRAME_OPTIONS = "DENY"`
- [ ] `SECURE_CONTENT_TYPE_NOSNIFF = True`
- [ ] `SESSION_COOKIE_SECURE = True`
- [ ] `CSRF_COOKIE_SECURE = True`
- [ ] `SECURE_SSL_REDIRECT = True`

#### Secrets
- [ ] No hardcoded credentials in source files
- [ ] `.env` is in `.gitignore`
- [ ] `SECRET_KEY` loaded from environment variable
- [ ] `storage_credentials/` is in `.gitignore`
- [ ] Database password not in any committed file

#### Platform-Specific Security
- [ ] Download endpoints enforce quota via `apps.firmwares` (`QuotaTier`/`DownloadToken`) before serving
- [ ] WAF rate limiting (`apps.security.RateLimitRule`) and download quotas (`apps.firmwares.QuotaTier`) are both active — they are separate systems
- [ ] Firmware upload validates file type (`.zip`, `.img`, etc.) via `SecurityConfig.allowed_upload_extensions`
- [ ] `apps.security.SecurityEvent` is emitted on all auth failures and suspicious actions
- [ ] `apps.security.SecurityConfig.crawler_guard_enabled` is `True` for production
- [ ] Affiliate redirect links (`apps.ads.AffiliateLink`) do not allow user-controlled redirect targets (SSRF)

#### Problems Tab / Code Quality
- [ ] VS Code Problems tab = zero issues (check with all filters disabled)
- [ ] `ruff check .` returns zero errors
- [ ] Pyright/Pylance shows no type errors or unresolved imports
- [ ] `manage.py check --settings=app.settings_dev` outputs `System check identified no issues`
- [ ] `manage.py check --deploy --settings=app.settings_production` passes in production

#### Admin Security
- [ ] All admin views (`apps/admin/views_*.py`, `admin_suite/` views) use `@staff_member_required` or `@user_passes_test(lambda u: u.is_staff)`
- [ ] **Never** use just `@login_required` on admin views — a logged-in non-staff user could access admin pages
- [ ] Admin API endpoints use `IsAdminUser` permission class, not `IsAuthenticated`
- [ ] Admin template URLs are not guessable (use named URL patterns, not hardcoded paths)

#### CSRF in Admin Forms
- [ ] Every admin `<form method="post">` includes `{% csrf_token %}`
- [ ] HTMX requests in admin templates include CSRF via `hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'` on `<body>` or on individual elements
- [ ] AJAX calls from `admin.js` include `X-CSRFToken` header (use `csrfFetch()` from `ajax.js`)
- [ ] No admin form uses `@csrf_exempt` — if an endpoint needs exemption, document why with a comment

#### Staff Decorator Enforcement

Run this script to verify all admin view functions have staff permission checks:

```python
# scripts/verify_admin_decorators.py
import ast
import sys
from pathlib import Path

STAFF_DECORATORS = {
    "staff_member_required",
    "user_passes_test",
    "permission_required",
    "login_required",  # flag as warning — should be staff_member_required
}

def check_file(filepath: Path) -> list[str]:
    issues = []
    tree = ast.parse(filepath.read_text())
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef):
            decorators = [
                d.attr if isinstance(d, ast.Attribute) else
                d.id if isinstance(d, ast.Name) else
                d.func.id if isinstance(d, ast.Call) and isinstance(d.func, ast.Name) else ""
                for d in node.decorator_list
            ]
            has_staff = any(d in {"staff_member_required", "user_passes_test", "permission_required"} for d in decorators)
            has_login_only = "login_required" in decorators and not has_staff
            if not has_staff and not has_login_only:
                issues.append(f"{filepath}:{node.lineno} — {node.name}() has NO auth decorator")
            elif has_login_only:
                issues.append(f"{filepath}:{node.lineno} — {node.name}() uses @login_required (should be @staff_member_required)")
    return issues

if __name__ == "__main__":
    admin_views = list(Path("apps/admin").glob("views_*.py"))
    all_issues = []
    for f in admin_views:
        all_issues.extend(check_file(f))
    for issue in all_issues:
        print(issue)
    sys.exit(1 if all_issues else 0)
```

### Step 4: Report
Generate findings as markdown table:

| File | Line | Severity | OWASP | Finding | Recommendation |
|---|---|---|---|---|---|

Then a summary section with total findings by severity (Critical / High / Medium / Low / Info).
