# Breakage Chains â€” Coupling Documentation

## Overview

A breakage chain is a sequence of dependencies where modifying one component
causes cascading failures in others. AI agents must understand these chains
before making changes to any component listed here.

**Why this matters**: An agent fixing a bug in `apps.core.models` could break
all 31 apps simultaneously. An agent modifying `base.html` could break every
page. These chains are the highest-risk modification targets in the codebase.

**Rule**: Before modifying ANY file listed in a breakage chain, read this
document first. If your change touches a chain root, test all downstream
components before considering the task complete.

---

## Chain Format

Each chain follows this structure:

- **ID**: Unique identifier (BC-XXX)
- **Severity**: Critical / High / Medium
- **Root**: The component whose modification triggers the cascade
- **Downstream**: Components affected by changes to the root
- **Trigger**: What kind of change causes the cascade
- **Impact**: What breaks and how
- **Prevention**: How to safely modify the root

---

## Known Chains

### BC-001: Core Model Shim â†’ All Apps

| Field | Value |
| ------- | ------- |
| **ID** | BC-001 |
| **Severity** | Critical |
| **Root** | `apps/core/models.py` (re-export shim) |
| **Downstream** | All 31 apps importing `TimestampedModel`, `SoftDeleteModel`, `AuditFieldsModel` |
| **Trigger** | Renaming, removing, or changing the signature of base model classes |
| **Impact** | Every model inheriting from these base classes fails to import. Migrations break. Server won't start. |
| **Prevention** | Never modify base model signatures without a full migration plan. The shim re-exports from `apps.site_settings.models` â€” modify the source, never the shim. Always run `manage.py check` after any change. |

---

### BC-002: Consent Middleware â†’ All Views

| Field | Value |
| ------- | ------- |
| **ID** | BC-002 |
| **Severity** | Critical |
| **Root** | `apps/consent/middleware.py` |
| **Downstream** | Every view in every app (middleware chain applies globally) |
| **Trigger** | Changing middleware logic, raising exceptions, altering request flow |
| **Impact** | All pages return errors or fail consent checks. Users locked out of the platform. |
| **Prevention** | Test middleware changes with all consent states (accepted, rejected, no decision). Never return JSON from consent views â€” always `HttpResponseRedirect`. Consent form views redirect to `HTTP_REFERER`. |

---

### BC-003: SiteSettings Singleton â†’ 10+ Apps

| Field | Value |
| ------- | ------- |
| **ID** | BC-003 |
| **Severity** | High |
| **Root** | `apps/site_settings/models.py` â†’ `SiteSettings` (django-solo singleton) |
| **Downstream** | `apps.seo`, `apps.ads`, `apps.blog`, `apps.firmwares`, `apps.admin`, `apps.consent`, `apps.security`, `apps.forum`, `apps.users`, `apps.analytics`, context processors |
| **Trigger** | Removing fields, renaming fields, changing field types or defaults |
| **Impact** | Apps reading removed fields crash with `AttributeError`. Templates referencing settings values fail silently or raise errors. |
| **Prevention** | Never remove SiteSettings fields â€” deprecate with a default value first. Always check which apps reference a field before modifying it. Use `grep_search` for the field name across the codebase. |

---

### BC-004: Security Middleware â†’ WAF Rate Limits

| Field | Value |
| ------- | ------- |
| **ID** | BC-004 |
| **Severity** | Critical |
| **Root** | `apps/security/middleware.py` + middleware ordering in `settings.py` |
| **Downstream** | All rate-limited endpoints, blocked IP enforcement, crawler guard |
| **Trigger** | Changing middleware order, disabling security middleware, modifying `RateLimitRule` enforcement logic |
| **Impact** | Rate limiting stops working. Blocked IPs can access the site. DDoS protection disabled. Crawlers bypass guards. |
| **Prevention** | Never reorder security middleware without understanding the full chain. Test with known blocked IPs after changes. Verify rate limits still apply with `curl` or load testing. |

---

### BC-005: Download Pipeline (Sequential)

| Field | Value |
| ------- | ------- |
| **ID** | BC-005 |
| **Severity** | High |
| **Root** | `apps/firmwares/download_service.py` |
| **Downstream** | `DownloadToken` â†’ `AdGateLog` â†’ `DownloadSession` (sequential pipeline) |
| **Trigger** | Changing token generation, validation, or pipeline order |
| **Impact** | Download tokens fail validation. Ad gates don't unlock. Download sessions never complete. Revenue tracking breaks. |
| **Prevention** | The pipeline must execute in order: `create_download_token()` â†’ `complete_ad_gate()` â†’ `start_download_session()` â†’ `complete_download_session()`. Never skip steps. Always test the full flow. |

---

### BC-006: User Model â†’ Every FK

| Field | Value |
| ------- | ------- |
| **ID** | BC-006 |
| **Severity** | Critical |
| **Root** | `apps/users/models.py` â†’ `User` model |
| **Downstream** | Every FK referencing `settings.AUTH_USER_MODEL` across all 31 apps |
| **Trigger** | Adding required fields without defaults, changing the user model class, modifying `AUTH_USER_MODEL` setting |
| **Impact** | All migrations fail. All FK lookups break. User creation fails. Authentication breaks. |
| **Prevention** | Never add required fields to User without providing a default or making them nullable. Always use `settings.AUTH_USER_MODEL` for FK references, never import User directly in models.py. Test migrations on a fresh database. |

---

### BC-007: Base Template â†’ All Pages

| Field | Value |
| ------- | ------- |
| **ID** | BC-007 |
| **Severity** | Critical |
| **Root** | `templates/base/base.html` |
| **Downstream** | Every template that extends `base.html` (100+ templates) |
| **Trigger** | Removing blocks, renaming blocks, breaking CDN fallback chain, altering `<head>` structure, changing theme initialization |
| **Impact** | All pages break visually. CDN libraries fail to load. Theme switching stops. Navigation disappears. |
| **Prevention** | Never remove or rename template blocks. Add new blocks alongside existing ones. Test CDN fallback chain (jsDelivr â†’ cdnjs â†’ unpkg â†’ local). Verify all three themes render correctly. Check the 23 reusable components still render. |

---

### BC-008: AdsSettings Singleton â†’ Ad Serving

| Field | Value |
| ------- | ------- |
| **ID** | BC-008 |
| **Severity** | High |
| **Root** | `apps/ads/models.py` â†’ `AdsSettings` (django-solo singleton) |
| **Downstream** | Ad serving pipeline, affiliate tracking, rewarded ad system, all ad templates |
| **Trigger** | Toggling `ads_enabled`, `affiliate_enabled`, removing fields, changing defaults |
| **Impact** | All ad serving stops. Affiliate links break. Revenue drops to zero. Rewarded ad credits stop accruing. |
| **Prevention** | Always test with both `ads_enabled=True` and `ads_enabled=False`. Never remove AdsSettings fields without auditing all templates and services that reference them. Check `apps/ads/services/` and `apps/ads/context_processors.py`. |

---

### BC-009: Celery â†’ Redis â†’ All Async Tasks

| Field | Value |
| ------- | ------- |
| **ID** | BC-009 |
| **Severity** | High |
| **Root** | `app/celery.py` + Redis broker configuration |
| **Downstream** | All `tasks.py` across every app, beat schedule, email queue, webhook delivery |
| **Trigger** | Redis connection failure, Celery config change, broker URL change, worker crash |
| **Impact** | All background tasks stop: email sending, webhook delivery, ad event aggregation, backup scheduling, scraper runs, analytics processing. Tasks queue indefinitely. |
| **Prevention** | Always verify Redis connectivity before deploying. Monitor Celery workers with `/celery-status` command. Set up dead letter queues. Configure task timeouts and retries. Never change `CELERY_BROKER_URL` without restarting all workers. |

---

### BC-010: QuotaTier â†’ Download Gating

| Field | Value |
| ------- | ------- |
| **ID** | BC-010 |
| **Severity** | Medium |
| **Root** | `apps/devices/models.py` â†’ `QuotaTier` |
| **Downstream** | `apps/firmwares/download_service.py` â†’ `DownloadToken` creation |
| **Trigger** | Changing tier limits, removing tiers, modifying `requires_ad` flag |
| **Impact** | Users get wrong download limits. Free users bypass ad gates. Premium users get restricted. Download quota enforcement inconsistent. |
| **Prevention** | Always verify the tier â†’ token â†’ download flow after modifying `QuotaTier`. Check that `create_download_token()` correctly reads the user's tier. Test all tier levels: Free, Registered, Subscriber, Premium. |

---

## Adding New Chains

When you discover a new coupling chain, add it here using this template:

```markdown
### BC-0XX: Short Description

| Field | Value |
| ------- | ------- |
| **ID** | BC-0XX |
| **Severity** | Critical / High / Medium |
| **Root** | `path/to/root/component` |
| **Downstream** | List of affected components |
| **Trigger** | What change causes the cascade |
| **Impact** | What breaks and user-visible effects |
| **Prevention** | How to safely modify the root component |
```

**Severity guidelines**:

- **Critical**: Server won't start, all users affected, data loss possible
- **High**: Major feature broken, significant user impact, revenue affected
- **Medium**: Subset of users affected, workaround exists, non-critical feature

---

*Last updated: 2026-04-14. Review chains quarterly or after architectural changes.*
