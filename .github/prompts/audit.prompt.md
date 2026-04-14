---
agent: 'agent'
description: 'Run a full 7-subagent audit across security, frontend, Django, commerce, SEO, ads, and distribution layers'
tools: ['semantic_search', 'read_file', 'grep_search', 'list_dir', 'file_search', 'run_in_terminal', 'get_errors']
---

# Full Platform Audit Orchestrator

Run a comprehensive 7-subagent audit of the GSMFWs platform. Execute each audit domain sequentially, collect all findings, and produce a unified report with severity levels and file locations.

## Audit Execution Plan

### Subagent 1 — Security Audit

Scan for OWASP Top 10 vulnerabilities:

1. **XSS Prevention** — Grep for `|safe` in templates without upstream `sanitize_html_content()` or `sanitize_ad_code()`. Check all user-input fields flow through `apps.core.sanitizers` before storage or display.
2. **CSRF Protection** — Verify `{% csrf_token %}` in all `<form method="POST">` tags. Confirm `<body hx-headers='{"X-CSRFToken": ...}'>` in `templates/base/base.html`. Grep for `@csrf_exempt` — each must be justified.
3. **SQL Injection** — Grep for `raw(`, `extra(`, `RawSQL(`, `.execute(` in all `apps/**/*.py`. Zero tolerance — Django ORM only.
4. **Auth/Authz** — Check all views in `apps/*/views*.py` for `@login_required` or `LoginRequiredMixin`. Verify staff views use `@user_passes_test(lambda u: u.is_staff)` or the `_render_admin` decorator.
5. **Secrets** — Grep for hardcoded API keys, passwords, tokens in `apps/**/*.py` and `app/settings*.py`. Verify all secrets load from environment variables.
6. **Session Security** — Check `SESSION_COOKIE_SECURE`, `SESSION_COOKIE_HTTPONLY`, `CSRF_COOKIE_SECURE` in production settings.
7. **File Uploads** — Verify MIME type, extension, and file size validation in upload views/services.
8. **CSP Headers** — Check `app/middleware/csp_nonce.py` exists and is in `MIDDLEWARE` list. Verify nonce injection in `base.html`.
9. **Rate Limiting** — Confirm `apps.security` WAF rules exist. Verify DRF throttle classes in `apps.core.throttling` are applied to API views.
10. **Dependencies** — Run `pip check` for broken dependency chains. Check for known CVEs.

### Subagent 2 — Frontend Audit

Scan all templates and static files:

1. **Alpine.js x-cloak** — Every element with `x-show`, `x-if`, or `x-data` with conditional rendering must have `x-cloak`. Grep `templates/**/*.html` for `x-show` without nearby `x-cloak`.
2. **HTMX Fragments** — Files in `templates/*/fragments/*.html` must NOT contain `{% extends %}`. They are standalone snippets.
3. **Theme Tokens** — Grep templates for hardcoded colors (`text-white`, `text-black`, `bg-white`, `bg-black`). These should use CSS custom properties (`--color-*`).
4. **Lucide Icons** — Verify `{% include "components/_icon.html" %}` usage pattern. Check icon sizes are consistent.
5. **Responsive Design** — Check for missing mobile breakpoints (`sm:`, `md:`, `lg:`). Verify no fixed-width containers without responsive overrides.
6. **CDN Fallback** — Verify `base.html` implements jsDelivr → cdnjs → unpkg → local vendor fallback chain.
7. **Print Stylesheet** — Check `static/css/src/_print.scss` exists and is imported.
8. **Accessibility** — Check `alt` attributes on images, `aria-label` on interactive elements, heading hierarchy (`h1` → `h2` → `h3` without skipping).
9. **Component Usage** — Grep for inline KPI cards, modals, pagination, search bars that should use `templates/components/` includes instead.
10. **Animation Conflicts** — Elements with `x-show` must not have CSS `animate-*` classes.

### Subagent 3 — Django Code Quality Audit

Scan all Python files in `apps/`:

1. **Model Meta** — Every model must have `class Meta` with `verbose_name`, `verbose_name_plural`, `ordering`, `db_table`.
2. **related_name** — Every `ForeignKey` and `ManyToManyField` must have `related_name`.
3. **Business Logic Placement** — Grep views for complex querysets, multi-model writes, or business rules. These belong in `services.py`.
4. **Type Hints** — All public functions/methods must have type annotations. `ModelAdmin` must be typed as `admin.ModelAdmin[MyModel]`.
5. **Admin Registration** — Every model in `apps/*/models.py` should have a corresponding registration in `apps/*/admin.py` or `apps/admin/`.
6. **URL Namespaces** — Every app with `urls.py` must define `app_name`. Check `app/urls.py` for proper `include()` with namespace.
7. **No Raw SQL** — Zero `raw()`, `extra()`, `RawSQL()`, `.cursor()` calls.
8. **Middleware Order** — Check `MIDDLEWARE` in settings for correct ordering (SecurityMiddleware first, then session, auth, etc.).
9. **App Boundaries** — `models.py` and `services.py` must not import from other apps (except `apps.core`, `apps.site_settings`, `AUTH_USER_MODEL`).
10. **Dissolved Apps** — Grep for imports referencing dissolved app names (`security_suite`, `crawler_guard`, `fw_scraper`, `download_links`, `admin_audit`, `email_system`, `webhooks`, `ai_behavior`, `device_registry`, `gsmarena_sync`, `fw_verification`).

### Subagent 4 — Commerce/Financial Audit

Scan wallet, shop, marketplace, bounty, referral, gamification, ads apps:

1. **select_for_update** — All wallet balance mutations must use `select_for_update()`. Grep `apps/wallet/services*.py` for balance changes without it.
2. **transaction.atomic** — All multi-model write operations must be wrapped in `@transaction.atomic`. Check services in wallet, shop, marketplace, bounty.
3. **Escrow Safety** — Marketplace transactions must use escrow hold → release pattern with dispute handling.
4. **Subscription Tiers** — QuotaTier enforcement in download flow. Verify `apps/firmwares/download_service.py` checks user tier.
5. **Affiliate Self-Referral** — Check that users cannot earn affiliate commission on their own purchases.
6. **Promo Code Limits** — Verify per-user and total usage caps are enforced.
7. **Download Quotas** — Verify DownloadToken creation checks daily/hourly limits from QuotaTier.
8. **Gamification Caps** — Points and badge awards must have daily/action limits to prevent abuse.
9. **Double-Entry Ledger** — Financial transactions should create balanced debit/credit entries.
10. **Audit Trail** — All financial operations must create audit log entries.

### Subagent 5 — SEO Audit

Scan seo app, templates, and content:

1. **Meta Tags** — Check all page templates include `<title>` and `<meta name="description">` tags.
2. **JSON-LD Schema** — Verify `SchemaEntry` records for key page types (Organization, WebSite, BlogPosting, SoftwareApplication, FAQPage).
3. **Sitemap** — Check `templates/sitemap.xml` and `templates/sitemap_index.xml` include all public content types.
4. **robots.txt** — Verify `templates/robots.txt` exists with proper Disallow rules and Sitemap reference.
5. **Canonical URLs** — Check templates use `<link rel="canonical">` to prevent duplicate content.
6. **Open Graph** — Verify `og:title`, `og:description`, `og:image`, `og:url` on all public pages.
7. **Breadcrumbs** — Check page templates use `{% include "components/_breadcrumb.html" %}`.
8. **Internal Linking** — Verify `LinkableEntity` and `LinkSuggestion` models are populated and linking engine active.
9. **Redirects** — Check for redirect chains (301 → 301) which should be collapsed.
10. **Heading Hierarchy** — Ensure single `<h1>` per page, proper `h2` → `h3` nesting.

### Subagent 6 — Ads System Audit

Scan ads app:

1. **Placement Config** — Verify `AdPlacement` records exist for all template slots.
2. **Format Templates** — Check ad format templates (banner, interstitial, native, video, rewarded, sticky) exist and render correctly.
3. **Consent Gating** — Ads must check consent status before serving personalized content.
4. **ads.txt** — Verify ads.txt endpoint exists and lists authorized sellers.
5. **Impression Tracking** — `AdEvent` creation on impression with proper deduplication.
6. **Revenue Analytics** — Verify analytics pipeline aggregates ad revenue data.
7. **Rewarded Ad Cooldowns** — Check `RewardedAdConfig` enforces cooldown and daily limits.
8. **Concurrency Policy** — Verify max ads per page limits from `AdsSettings.aggressiveness`.
9. **Responsive Slots** — Ad containers must have responsive sizing per breakpoint.
10. **Affiliate Pipeline** — Check `AffiliateLink`, `AffiliateClick` tracking is functional.

### Subagent 7 — Distribution Audit

Scan distribution app:

1. **Connector Health** — Verify all configured social connectors have valid credentials.
2. **Credential Validation** — Check API token expiry and refresh logic.
3. **Circuit Breaker** — Verify circuit breaker pattern prevents cascade failures on API outages.
4. **Rate Limits** — Per-platform rate limits must be enforced to prevent API bans.
5. **Message Builder** — Templates render correctly for each platform's format requirements.
6. **UTM Injection** — Outbound links must include UTM parameters for attribution.
7. **Deduplication** — Check that duplicate posts to same channel are prevented.
8. **Auto-Publish** — Verify signal-driven auto-publish on blog post creation works.
9. **Retry Logic** — Failed distribution jobs must retry with exponential backoff.
10. **WebSub** — Check WebSub hub notification on content publish.

## Report Format

For each finding, output:

```
[SEVERITY] CATEGORY — Description
  File: path/to/file.py:LINE
  Fix: Brief remediation guidance
```

Severity levels: `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`, `[INFO]`

## Final Summary

After all 7 subagents complete, produce a summary table:

| Domain | Critical | High | Medium | Low | Info | Score |
|--------|----------|------|--------|-----|------|-------|
| Security | | | | | | /100 |
| Frontend | | | | | | /100 |
| Django | | | | | | /100 |
| Commerce | | | | | | /100 |
| SEO | | | | | | /100 |
| Ads | | | | | | /100 |
| Distribution | | | | | | /100 |
| **OVERALL** | | | | | | **/100** |
