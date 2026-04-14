---
agent: 'agent'
description: 'Scan all regression monitors for XSS, CSRF, auth, HTMX, Alpine, app boundaries, and type safety regressions'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal', 'get_errors']
---

# Regression Monitor Scan

Run all regression detection monitors against the codebase. Each monitor checks for patterns that have caused regressions in the past. Any finding means a regression may have been introduced.

## Monitor 1 — XSS Regression

1. Grep `templates/**/*.html` for `|safe` filter usage. Each must have a verified sanitized source.
2. Grep `apps/*/models.py` and `apps/*/services*.py` for HTML storage without `sanitize_html_content()`.
3. Verify `apps.core.sanitizers` uses `nh3` (NOT `bleach` — bleach is deprecated and replaced).
4. Check that no removed sanitization guards have been re-introduced as plain passthrough.

## Monitor 2 — CSRF Regression

1. Verify `CsrfViewMiddleware` is in `MIDDLEWARE` list (not removed or commented out).
2. Grep for `@csrf_exempt` — each must have documented justification.
3. Verify `<body hx-headers='{"X-CSRFToken": ...}'>` still exists in `base.html`.
4. Check all `<form method="POST">` in changed templates include `{% csrf_token %}`.

## Monitor 3 — CSP Regression

1. Verify `app/middleware/csp_nonce.py` is in `MIDDLEWARE`.
2. Check `base.html` inline scripts use `nonce="{{ csp_nonce }}"`.
3. Grep for new inline `<script>` tags without nonce attribute.
4. Verify CSP header hasn't been weakened (no `unsafe-inline`, no `unsafe-eval` additions).

## Monitor 4 — Auth Regression

1. Scan all views for missing `@login_required` or `LoginRequiredMixin`.
2. Check staff views use `getattr(request.user, "is_staff", False)` pattern, not bare `.is_staff`.
3. Verify ownership checks in user-specific data access: `.get(pk=pk, user=request.user)`.
4. Check `_render_admin` decorator still enforces `is_staff` check.

## Monitor 5 — Session Security Regression

1. Verify `SESSION_COOKIE_SECURE` and `SESSION_COOKIE_HTTPONLY` in production settings.
2. Check `CSRF_COOKIE_SECURE` in production settings.
3. Verify session rotation on login hasn't been disabled.
4. Check `SESSION_COOKIE_SAMESITE` is set to `"Lax"` or `"Strict"`.

## Monitor 6 — HTMX Fragment Regression

1. Scan `templates/*/fragments/*.html` for `{% extends %}` — absolute zero tolerance.
2. Verify fragment views return fragment template (not full page) when `HX-Request` header present.
3. Check HTMX response headers (`HX-Trigger`, `HX-Redirect`) are properly set.

## Monitor 7 — Alpine.js Regression

1. Every `x-show` and `x-if` element must have `x-cloak`.
2. No CSS `animate-*` class on elements with `x-show` (causes flicker).
3. `x-data` components must be self-contained — no global variable leaks.
4. `$dispatch` events must have listener somewhere in the DOM tree.

## Monitor 8 — Tailwind/Theme Regression

1. No hardcoded `text-white`, `text-black`, `bg-white`, `bg-gray-900` — use theme tokens.
2. `--color-accent-text` must NOT be assumed white — it's BLACK in contrast theme.
3. Verify all three themes (dark, light, contrast) still have complete variable sets in `_themes.scss`.
4. Check for CSS that breaks in any of the three themes.

## Monitor 9 — App Boundary Regression

1. Grep `apps/*/models.py` for imports from other apps (except `apps.core`, `apps.site_settings`, `AUTH_USER_MODEL`).
2. Grep `apps/*/services*.py` for direct cross-app service calls (should use EventBus or signals).
3. Verify `apps/admin/` is the only app importing from all others.
4. Check for circular imports between apps.

## Monitor 10 — Dissolved App Regression

Grep entire codebase for references to dissolved app names:
```
security_suite, security_events, crawler_guard, ai_behavior,
device_registry, gsmarena_sync, fw_verification, fw_scraper,
download_links, admin_audit, email_system, webhooks
```
Any import, string reference, or URL pattern using these names is a CRITICAL regression.

## Monitor 11 — Model Meta Regression

1. Check all models have `class Meta` with `verbose_name`, `verbose_name_plural`, `ordering`, `db_table`.
2. Verify all FK/M2M fields have `related_name`.
3. Verify all models have `__str__` method.
4. Dissolved models retain `db_table = "original_app_tablename"`.

## Monitor 12 — Type Safety Regression

1. No blanket `# type: ignore` — must specify error code.
2. `ModelAdmin` must be typed: `admin.ModelAdmin[MyModel]`.
3. `get_queryset()` must have return type: `-> QuerySet[MyModel]`.
4. Public API functions must have type annotations.
5. Check `get_errors()` for any Pylance/Pyright errors.

## Monitor 13 — Test Coverage Regression

1. Check for deleted test files without replacement.
2. Verify new code has corresponding tests.
3. Check for `@pytest.mark.skip` or `@unittest.skip` additions without justification.
4. Run `& .\.venv\Scripts\python.exe -m pytest --co -q` to verify test discovery.

## Monitor 14 — Migration Consistency

1. Run `& .\.venv\Scripts\python.exe manage.py makemigrations --check --settings=app.settings_dev` — should produce no new migrations.
2. Verify migration files haven't been manually edited (check git diff).
3. Check for conflicting migration numbers.

## Monitor 15 — Requirements Drift

1. Verify every import in `apps/**/*.py` has corresponding entry in `requirements.txt`.
2. Check `requirements.txt` entries are all actually used.
3. Run `& .\.venv\Scripts\pip.exe check` for broken dependency chains.
4. Verify no `bleach` — replaced by `nh3`.

## Report Format

```
[REGRESSION] Monitor N — Finding Title
  Evidence: What was found
  File: path/to/file.py:LINE
  Impact: What breaks
  Fix: Remediation
```

Summary: Total regressions found, categorized by severity. If zero regressions: output "✅ All 15 regression monitors CLEAN".
