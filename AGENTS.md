# Project Guidelines

## Overview

Enterprise-grade Django 5.2 full-stack platform for firmware distribution — inspired by and outperforming comparable firmware distribution platforms. Django-served frontend (Tailwind CSS v4 + Alpine.js v3 + HTMX v2 + Lucide Icons) with DRF API endpoints. PostgreSQL 17, Celery + Redis for async tasks. JWT authentication, allauth for social auth, freemium + subscription download model.

Platform pillars: automated OEM firmware scraping, AI behaviour analytics, verified tester programme, full affiliate marketing, gamification, bounty/marketplace, and subscription-tier download quotas.

## Architecture

31 Django apps in `apps/` — all consolidated, zero dissolved stubs remaining.

```text
app/                  # Project config (settings, urls, wsgi, asgi, celery)
apps/                 # All Django apps (31 — post-consolidation)
  # --- Infrastructure ---
  core/               # Enterprise infrastructure layer: exception handling, caching (DistributedCacheManager),
                      # AI facade (CoreAiService), sanitization (nh3-based XSS prevention), throttling
                      # (6 DRF classes), event bus (EventBus, EventTypes), signals (firmware_uploaded,
                      # storage_quota_exhausted), email/queue/storage service abstractions, utils,
                      # middleware, webhooks. NOTE: models.py is a shim that re-exports
                      # TimestampedModel, SoftDeleteModel, AuditFieldsModel from apps.site_settings
  consent/            # Privacy/consent enforcement layer: consent UI views, REST API (get/update status),
                      # middleware (request-level enforcement), @consent_required decorator,
                      # context_processors, signals, utils (hash_ip, hash_ua, check, get_active_policy).
                      # Consent scopes: functional (required), analytics, seo, ads.
                      # NOTE: models.py is a shim re-exporting ConsentPolicy, ConsentRecord,
                      # ConsentDecision, ConsentEvent, ConsentLog, ConsentCategory from apps.users
  site_settings/      # Global singleton config (django-solo) + base models (TimestampedModel,
                      # SoftDeleteModel, AuditFieldsModel) + SiteSettings (branding, SEO, security,
                      # download config, theme, social links, maintenance mode)
  # --- Auth & Users ---
  users/              # User accounts, profiles, JWT auth, consent models (ConsentPolicy, ConsentRecord,
                      # ConsentDecision, ConsentEvent, ConsentLog, ConsentCategory), MFA, email verification
  user_profile/       # Extended user profile (bio, social links, preferences, reputation)
  # --- Administration ---
  admin/              # Custom admin panel — 8 view modules (views_auth, views_content,
                      # views_distribution, views_extended, views_infrastructure, views_security,
                      # views_settings, views_users) + shared helpers (views_shared.py with
                      # _render_admin decorator). 57 admin templates + AuditLog, AdminAction, FieldChange
                      # (absorbed: admin_audit)
  # --- Devices ---
  devices/            # Device catalog, DeviceConfig, DeviceEvent, DeviceFingerprint,
                      # TrustScore, QuotaTier, BehaviorInsight
                      # (absorbed: device_registry, ai_behavior)
  # --- Firmware Mega-App ---
  firmwares/          # Firmware files (Official, Engineering, Readback, Modified, Other) +
                      # Brand/Model/Variant catalog + verification (TrustedTester, VerificationReport) +
                      # OEM scraper (OEMSource, ScraperConfig, ScraperRun, IngestionJob) +
                      # download gating (DownloadToken, DownloadSession, AdGateLog, HotlinkBlock,
                      # download_service.py) + GSMArena spec sync (GSMArenaDevice, SyncRun, SyncConflict)
                      # (absorbed: fw_verification, fw_scraper, download_links, gsmarena_sync)
  # --- Content ---
  blog/               # Blog posts, categories, versioning, feeds, AI editor, auto-publishing workflow
  tags/               # Polymorphic tagging system
  comments/           # User comments with moderation, consent-gated
  pages/              # Static CMS pages (about, terms, privacy, etc.)
  ads/                # Ad campaigns + full affiliate marketing (AffiliateProvider, AffiliateProduct,
                      # AffiliateLink, AffiliateClick, AffiliateProductMatch, AffiliateSource)
  seo/                # Full-featured SEO engine: Metadata, SchemaEntry (JSON-LD), SitemapEntry
                      # (XML sitemaps with XSLT human-readable stylesheet), Redirect (301/302),
                      # LinkableEntity + LinkSuggestion (internal linking engine), SEOSettings +
                      # SeoAutomationSettings (AI meta generation, auto-tags, auto-schema).
                      # robots.txt, Open Graph, sitemap index. Own admin panel section.
  # --- Community ---
  forum/              # Full-featured community forum: categories, topics, replies, polls,
                      #   reactions, trust levels, user profiles, wiki headers, changelogs,
                      #   FAQ entries, private messages, search, leaderboard, online users,
                      #   4PDA-style features, inline HTMX search, device linking,
                      #   moderation (warnings, IP bans, move/merge), bookmarks, subscriptions
  # --- Commerce ---
  shop/               # Product listings, orders
  wallet/             # User wallet, credits, transactions
  marketplace/        # P2P firmware/resource marketplace
  bounty/             # Firmware bounty program
  referral/           # Referral program, codes, rewards
  gamification/       # Points, badges, leaderboards
  # --- Security ---
  security/           # Unified WAF security: SecurityConfig, SecurityEvent, RateLimitRule,
                      # BlockedIP, CSPViolationReport, CrawlerRule, CrawlerEvent
                      # (absorbed: security_suite, security_events, crawler_guard)
  # --- Distribution (Social/Content Syndication) ---
  distribution/       # Blog/social content syndication (Twitter, LinkedIn, WebSub) — NOT firmware
  # --- AI & Analytics ---
  ai/                 # AI providers, completions, prompt management
  analytics/          # Traffic, download, revenue, affiliate analytics
  # --- Communication ---
  notifications/      # In-app/push notifications + EmailTemplate/Queue + WebhookEndpoint/Delivery
                      # (absorbed: email_system, webhooks)
  # --- Operations ---
  storage/            # GCS/local file storage abstraction
  backup/             # Automated backup scheduling and restore
  moderation/         # Content moderation queue
  changelog/          # Changelog entries and version releases
  api/                # Top-level API gateway, versioning, health checks
  i18n/               # Internationalization utilities
templates/            # Django templates (base layouts, pages, 23 components, HTMX fragments)
static/               # Static assets (SCSS, JS, vendor libs, images, fonts)
scripts/              # Management and maintenance scripts
```

---

## Core Infrastructure (`apps.core`)

`apps.core` is the shared enterprise infrastructure layer used by 10+ apps. **Only `models.py` is a shim** — everything else is active production code.

| Module | Purpose | Key Exports |
| --- | --- | --- |
| `exceptions.py` | Safe error handling (hides details when `DEBUG=False`) | `json_error_response()` |
| `cache.py` | Multi-site distributed cache with key namespacing | `DistributedCacheManager` |
| `ai.py` / `ai_client.py` | Centralized AI service facade with observability | `CoreAiService`, `generate_text()`, `classify_text()` |
| `sanitizers.py` | XSS prevention via nh3 (Rust-based, replaced bleach) | `sanitize_ad_code()`, `sanitize_html_content()` |
| `throttling.py` | 6 DRF rate limit classes | `UploadRateThrottle`, `DownloadRateThrottle`, `APIRateThrottle` |
| `signals.py` | Platform-level signal definitions | `firmware_uploaded`, `firmware_download_ready`, `storage_quota_exhausted` |
| `events/bus.py` | Decoupled event bus for cross-app communication | `EventBus`, `EventTypes`, `event_bus` singleton |
| `infrastructure/` | Service abstractions | `EmailService`, `QueueService`, `StorageService` |
| `services/` | Service implementations | `NotificationService`, `SettingsProvider` |
| `interfaces.py` | Abstract base classes for decoupling | `SettingsProvider`, `NotificationService`, `CacheService` |
| `app_service.py` | App context service | Used by seo, ads, blog, comments, tags, users |
| `utils/` | Cross-app utilities | `feature_flags`, `get_client_ip()`, `log_event()`, `sanitize_html()` |

**Allowed import:** `from apps.core.models import TimestampedModel` and any `apps.core` utility.

---

## Quality Gate — Zero Tolerance (MANDATORY)

**Every agent, every task — run before starting AND after completing:**

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

**Zero issues allowed in:**

- VS Code Problems tab — check ALL items including hidden/suppressed ones (`View → Problems`, ensure no active filters)
- Ruff: E, W, F, I, N, UP, B, C4, SIM, RUF error codes
- Pyright / Pylance: type errors, missing imports, unresolved symbols
- `manage.py check`: must output `System check identified no issues (0 silenced)`
- `manage.py check --deploy` in production settings

**Fixing common Pylance/Pyright issues:**

- Missing stubs → `pip install djangorestframework-stubs django-stubs types-requests`
- `ModelAdmin` without type param → `class MyAdmin(admin.ModelAdmin[MyModel]):`
- `get_queryset()` return type → annotate as `QuerySet[MyModel]`
- `solo.models` has no stubs → suffix with `# type: ignore[import-untyped]`
- Unresolved import with no stub → `# type: ignore[import-untyped]` (never blanket `# type: ignore`)
- Django reverse FK managers (e.g. `brand.models`) not resolved → `# type: ignore[attr-defined]`
- Narrowing `QuerySet.first()` result → use `TYPE_CHECKING` import + proper type annotation on helper parameters

---

## Rate Limiting — Two Separate Systems

### 1 — WAF / Security Rate Limiting (`apps.security`)

IP/path-based hard limits enforced at middleware level. Protects against DDoS, bot abuse, API scraping.

| Model | Purpose |
| --- | --- |
| `SecurityConfig` | Singleton: MFA policy, crawler guard toggle, login risk policy, device quotas, CSRF origins |
| `SecurityEvent` | Audit log (login_fail, mfa_fail, rate_limited, ip_blocked, download_abuse, etc.) |
| `RateLimitRule` | Per-path rules (limit, window_seconds, action: throttle/block/log) |
| `BlockedIP` | Permanent or timed IP blocks |
| `CSPViolationReport` | Content-Security-Policy violation reports |
| `CrawlerRule` | Bot/crawler path rules (requests_per_minute, action: allow/throttle/block/challenge) |
| `CrawlerEvent` | Log of every matched crawler request |

Config via `SecurityConfig` singleton: `crawler_guard_enabled`, `crawler_default_action`, `login_risk_policy`.

### 2 — Download Quota System (`apps.firmwares` + `apps.devices`)

Per-user/tier download limits enforced at firmware download time. Powers the freemium model.

**Tier definitions** (`apps.devices`):

| Model | Purpose |
| --- | --- |
| `DeviceConfig` | Global fingerprinting policy, quotas, MFA rules, AI risk scoring |
| `QuotaTier` | Tier config (daily/hourly limits, requires_ad, can_bypass_captcha) |

**Download enforcement** (`apps.firmwares`):

| Model | Purpose |
| --- | --- |
| `DownloadToken` | Single-use per-firmware per-user token (ad_gate_required, expiry, status: active/used/expired/revoked) |
| `DownloadSession` | Tracks download lifecycle (bytes_delivered, start/complete/fail) |
| `AdGateLog` | Ad watch tracking (video/banner/interstitial, watched_seconds, credits_earned) |
| `HotlinkBlock` | Domain-level hotlinking protection |

**Service layer** (`apps.firmwares.download_service`):

| Function | Purpose |
| --- | --- |
| `create_download_token()` | Creates HMAC-signed token with ad-gate and expiry |
| `validate_download_token()` | Verifies HMAC signature, checks expiry and status |
| `complete_ad_gate()` | Records ad completion and unlocks download |
| `check_hotlink_protection()` | Validates referrer against allowed domains |
| `check_rate_limit()` | Per-user download rate enforcement |
| `start_download_session()` | Initiates tracked download |
| `complete_download_session()` | Marks download as finished with byte count |

Tiers: Free (ad-gated) → Registered → Subscriber → Premium. Limits: per-GB, per-file, per-24h.

> **Never conflate these two systems.** WAF limits → `apps.security`. Download quotas → `apps.firmwares` + `apps.devices`.

---

## Device Trust & Behavior (`apps.devices`)

| Model | Purpose |
| --- | --- |
| `DeviceConfig` | Global device fingerprinting policy, quotas, MFA rules, AI risk scoring |
| `Device` | Registered device record (user, OS, browser, last_seen) |
| `DeviceEvent` | Activity log (login, download_attempt, policy_violation, etc.) |
| `DeviceFingerprint` | OS, browser, device type, trust level, bot detection |
| `TrustScore` | Computed score with signal tracking |
| `BehaviorInsight` | AI-flagged anomalies (severity: low/medium/high/critical) |

---

## Ads Management System (`apps.ads`)

Full autonomous ads management system co-located with affiliate marketing. 18+ models covering ad serving, campaigns, rewarded ads, auto-ads scanning, and a multi-network affiliate pipeline.

### Core Ad Models

| Model | Purpose |
| --- | --- |
| `AdsSettings` | Singleton config: `ads_enabled`, `ad_networks_enabled`, `affiliate_enabled`, `aggressiveness` |
| `AdNetwork` | 18 network types (adsense, ad_manager, media_net, ezoic, mediavine, propeller, etc.) with priority/status |
| `AdUnit` | Unit config per network (unit_id, format: banner/interstitial/native/video/rewarded/sticky) |
| `AdPlacement` | Named placement slots in templates (header, sidebar, in-content, footer, etc.) |
| `Campaign` | Budget, daily/total caps, targeting rules, `start_at`/`end_at` scheduling, status |
| `AdCreative` | Creative assets (title, body, image, CTA URL, click/impression counts) |
| `PlacementAssignment` | Weighted creative ↔ placement binding with lock/priority controls |
| `AdEvent` | Analytics events (impression, click, viewable, conversion) with timestamp + user FK |
| `RewardedAdConfig` | Reward rules (credits, premium_hours, ad_free_hours, cooldown, daily_limit) |
| `RewardedAdView` | User reward tracking per view (credits_earned, completed flag) |
| `AutoAdsScanResult` | AI template scan results: discovered placement locations, confidence scores |

### Affiliate Models

| Model | Purpose |
| --- | --- |
| `AffiliateProvider` | Network config (Amazon, AliExpress, Banggood, CJ, ShareASale, Rakuten, eBay, Awin, Impact), API keys, cookie duration |
| `AffiliateProductCategory` | Product taxonomy |
| `AffiliateProduct` | Product listings with commission rates and deep links |
| `AffiliateSource` | Traffic source tracking |
| `AffiliateLink` | Tracked outbound links with UTM parameters |
| `AffiliateClick` | Every click recorded for commission attribution |
| `AffiliateProductMatch` | Auto-matching firmware device models to relevant affiliate products |

### Service Layer (`apps/ads/services/`)

| Service | Purpose |
| --- | --- |
| `rotation.py` | Weighted creative rotation per placement with priority and lock controls |
| `targeting.py` | Campaign targeting (geo, device, user segment, time-of-day) |
| `analytics.py` | Event tracking and aggregation |
| `affiliate.py` | Affiliate link resolution and click attribution |
| `ai_optimizer.py` | AI-powered placement optimization and creative scoring |
| `schemas.py` | DRF serializers for ad and affiliate endpoints |

### Celery Tasks

| Task | Schedule | Purpose |
| --- | --- | --- |
| `aggregate_events` | Periodically | Aggregate AdEvent data for dashboard reporting |
| `cleanup_old_events` | Daily | Remove stale ad events beyond retention window |
| `scan_templates_for_ad_placements` | On demand | AI scan of Django templates for optimal ad slot discovery |
| `ai_optimize_ad_placements` | Weekly | AI analysis of placement performance with optimization suggestions |

API: `apps/ads/api.py` — ad serving, click tracking, and affiliate endpoints under `/api/v1/ads/`.
Revenue tracking: events emitted to `apps.analytics` for attribution and commission reporting.

---

## Enterprise Platform Vision

Outperforms Easy Firmware Store Ultimate (Jaudi Softs) through:

- Automated OEM firmware scraping (`OEMSource`, `ScraperConfig`) with AI-assisted ingestion
- Verified tester programme (`TrustedTester`, `VerificationReport`) for firmware quality assurance
- AI behaviour analytics (`BehaviorInsight`) for anti-abuse and trust scoring
- Full affiliate marketing alongside ad campaigns — dual ad-revenue model
- **Full-featured community forum** (4PDA/vBulletin/Discourse-inspired) with polls, reactions, wiki headers, device linking, trust levels, private messages, moderation, inline search
- Gamification (points, badges, leaderboards) for community engagement
- Bounty system for crowd-sourced firmware sourcing
- P2P marketplace for firmware/device resource trading
- Subscription wallet with credits, referral rewards, and ad-unlock gates

---

## Community Forum (`apps.forum`)

Full-featured community forum inspired by 4PDA, vBulletin, and Discourse. Self-contained Django app with services layer, HTMX fragments, and Alpine.js interactivity.

### Models (30+)

| Model | Purpose |
| --- | --- |
| `ForumCategory` | Hierarchical categories (parent/child) with icons, colours, privacy, sort order |
| `ForumTopic` | Discussion threads with prefix, type, wiki header, device linking |
| `ForumReply` | Thread replies with Markdown, @mentions, edit history |
| `ForumPoll` / `ForumPollChoice` / `ForumPollVote` | Topic polls (single/multiple, secret ballot) |
| `ForumReaction` / `ForumReplyReaction` | Configurable reactions (Like, Love, Insightful, Funny, Agree, Disagree) |
| `ForumTrustLevel` | Discourse-style auto-promotion criteria |
| `ForumUserProfile` | Per-user forum stats, reputation, signatures, custom titles |
| `ForumTopicPrefix` / `ForumTopicTag` | vBulletin-style prefixes + topic tags |
| `ForumBestAnswer` | Accepted solutions for help topics |
| `ForumTopicRating` | Star ratings on topics |
| `ForumBookmark` / `ForumTopicFavorite` | Saved topics and reply bookmarks |
| `ForumTopicSubscription` / `ForumCategorySubscription` | Email/in-app notifications |
| `ForumPrivateTopic` / `ForumPrivateTopicUser` | Private messaging system |
| `ForumFlag` | Content flagging for moderation |
| `ForumWarning` / `ForumIPBan` | Moderation tools |
| `ForumOnlineUser` | Real-time presence tracking |
| `ForumTopicMoveLog` / `ForumTopicMergeLog` | Moderation audit trail |
| `ForumAttachment` | File attachments with download counter |
| `ForumReplyHistory` / `ForumMention` | Edit tracking and @mention resolution |
| `ForumUsefulPost` | 4PDA "useful" post marks |
| `ForumFAQEntry` | 4PDA per-topic FAQ sidebar |
| `ForumChangelog` | 4PDA per-topic changelog timeline |
| `ForumWikiHeaderHistory` | 4PDA wiki header (шапка) edit history |

### 4PDA-Specific Features

- **Topic types**: Discussion, Firmware, FAQ, Guide, News, Review, Bug Report
- **Wiki headers (шапка)**: Collaboratively editable header post with Markdown, edit history
- **Device linking**: FK to `firmwares.Model` for device-specific topics
- **Changelog**: Per-topic version timeline with rich text and release dates
- **FAQ entries**: Per-topic FAQ sidebar linking to specific replies
- **Useful post marks**: Community-driven answer highlighting with reputation rewards
- **Attachment download counts**: Per-file download tracking

### Service Layer (`services.py`)

All business logic in `apps/forum/services.py`. Views call services — never put logic in views.

Key functions: `create_topic()`, `create_reply()`, `toggle_like()`, `toggle_favorite()`, `create_poll()`, `cast_vote()`, `update_wiki_header()`, `toggle_useful_post()`, `add_faq_entry()`, `add_changelog_entry()`, `search_topics()`, `get_online_users()`, `get_forum_stats()`, `get_trending_topics()`, `get_recent_topics()`, `get_latest_replies()`, `evaluate_trust_level()`, `move_topic()`, `merge_topics()`.

### URL Patterns

All under `forum:` namespace. Category: `c/<slug>/`, Topic: `t/<pk>/<slug>/`, Search: `search/`, Private: `messages/`, Leaderboard: `leaderboard/`, Online: `whos-online/`.

### Templates

- `forum_index.html` — Enriched landing page (stats bar, inline search, trending, categories, sidebar)
- `category_detail.html` — Topic listing with search
- `topic_detail.html` — Full topic view with wiki header, polls, replies, reactions
- `fragments/` — 15+ HTMX fragments for partial updates (search results, category cards, reply items, poll widget, reactions, wiki header, useful button, FAQ, changelog, etc.)

### Management Command

```powershell
& .\.venv\Scripts\python.exe manage.py seed_forum --settings=app.settings_dev
```

Seeds 8 test users, 12 categories, 10 topics, 23 replies, polls, tags, wiki headers, changelogs, FAQ entries, and online users for visual smoke testing.

---

## Frontend Architecture

Django-served frontend — zero separate SPA, zero extra hosting cost. All templates rendered server-side with progressive enhancement via HTMX and Alpine.js.

### Technology Stack

| Technology | Version | Role | CDN |
| --- | --- | --- | --- |
| Tailwind CSS | v4 | Utility-first CSS framework | jsDelivr → cdnjs → unpkg → local |
| Alpine.js | v3 | Lightweight client-side reactivity | jsDelivr → cdnjs → unpkg → local |
| HTMX | v2 | HTML-over-the-wire partial updates | jsDelivr → cdnjs → unpkg → local |
| Lucide Icons | v0.460+ | SVG icon library (pin major version) | jsDelivr → cdnjs → unpkg → local |
| SCSS | — | Custom styles, theme variables | Compiled locally |

### Multi-CDN Fallback Order

1. **jsDelivr** (primary) — fastest, most reliable
2. **cdnjs** (fallback 1)
3. **unpkg** (fallback 2)
4. **Local vendor** (fallback 3) — bundled in `static/vendor/`

### Theme System — 3 Switchable Themes

All themes use CSS custom properties on `<html data-theme="dark|light|contrast">`:

| Theme | Slug | Description |
| --- | --- | --- |
| Dark Tech | `dark` | Default. Dark backgrounds, cyan/blue accents |
| Light Professional | `light` | White backgrounds, slate text, blue accents |
| High Contrast | `contrast` | Maximum readability, WCAG AAA, strong borders |

Theme switching: Alpine.js `x-data` stores preference in `localStorage`, applies `data-theme` attribute. CSS variables cascade automatically.

**Critical gotcha:** `--color-accent-text` is WHITE in dark/light themes but BLACK in contrast theme. Always use the token — never hardcode white/black on accent backgrounds.

### Template Hierarchy

```text
templates/
  base/
    base.html              # Root: DOCTYPE, <head>, <body>, CDN fallback chain, theme init
    nav.html               # Navigation bar
    footer.html            # Footer
    messages.html          # Toast notifications
  layouts/
    default.html           # Standard page (nav + content + footer)
    dashboard.html         # Sidebar + content
    auth.html              # Auth pages (login, register)
    minimal.html           # Error pages
  components/              # 23 reusable partials (4 admin + 19 enduser):
                           #   Admin: _admin_kpi_card, _admin_search, _admin_table, _admin_bulk_actions
                           #   Enduser: _card, _modal, _alert, _confirm_dialog, _tooltip, _badge,
                           #     _breadcrumb, _empty_state, _field_error, _form_errors, _form_field,
                           #     _icon, _loading, _pagination, _progress_bar, _search_bar,
                           #     _section_header, _stat_card, _theme_switcher
  <app>/                   # Per-app templates (blog/, firmwares/, devices/, shop/, admin/)
    <app>/fragments/       # HTMX fragments for partial updates
```

### HTMX View Pattern

Views that serve both full pages and HTMX fragments:

```python
def firmware_list(request):
    firmwares = Firmware.objects.filter(is_active=True)
    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/list.html", {"firmwares": firmwares})
    return render(request, "firmwares/list.html", {"firmwares": firmwares})
```

### Static File Structure

```text
static/
  css/src/               # SCSS source (main.scss, _variables, _themes, _animations, etc.)
  css/dist/              # Compiled CSS + Tailwind output
  js/src/                # JS modules (theme-switcher, ajax, notifications, alpine-components)
  js/dist/               # Minified JS
  vendor/                # Local CDN fallbacks (tailwind, alpine, htmx, lucide)
  img/                   # Images, logos, favicons, brand SVGs (44+ brands)
  fonts/                 # Custom fonts (Inter, JetBrains Mono — WOFF2)
```

### Build Pipeline

- **Development**: CDN for all libraries, zero build step, instant reload
- **Production**: Tailwind CLI standalone compiles CSS, WhiteNoise serves static files
- **CI/CD**: `tailwindcss -i static/css/src/main.scss -o static/css/dist/main.css --minify`

---

## Dissolved Apps Reference

All dissolved apps have been **fully removed** — no stub directories remain. Models migrated to target apps use `db_table = "original_app_tablename"` in Meta to preserve existing data.

**Import from the target app only — never reference dissolved app names in imports.**

| Dissolved App | Target App | Models Moved |
| --- | --- | --- |
| `security_suite` | `apps.security` | SecurityConfig fields merged |
| `security_events` | `apps.security` | SecurityEvent fields merged |
| `crawler_guard` | `apps.security` | CrawlerRule, CrawlerEvent |
| `ai_behavior` | `apps.devices` | BehaviorInsight |
| `device_registry` | `apps.devices` | DeviceFingerprint, TrustScore, QuotaTier, RegistryEvent |
| `gsmarena_sync` | `apps.firmwares` | GSMArenaDevice, SyncRun, SyncConflict |
| `fw_verification` | `apps.firmwares` | TrustedTester, VerificationReport, TestResult, VerificationCredit |
| `fw_scraper` | `apps.firmwares` | OEMSource, ScraperConfig, ScraperRun, IngestionJob |
| `download_links` | `apps.firmwares` | DownloadToken, DownloadSession, AdGateLog, HotlinkBlock |
| `admin_audit` | `apps.admin` | AuditLog, AdminAction, FieldChange |
| `email_system` | `apps.notifications` | EmailTemplate, EmailQueue, EmailBounce, EmailLog |
| `webhooks` | `apps.notifications` | WebhookEndpoint, WebhookDelivery, DeliveryAttempt |

---

## Code Style

- Python 3.12+, Django 5.2, **full type hints on all public APIs** (enforced by Pyright/Pylance)
- Ruff for linting and formatting (line-length 88, target-version = "py312")
- **Zero tolerance: no lint warnings, no type errors, no unused imports, no Pylance/Pyright issues**
- All dependencies (including type stubs) managed in `requirements.txt` — see § Requirements Management
- `ModelAdmin` must be typed: `class MyAdmin(admin.ModelAdmin[MyModel]):`
- `get_queryset()` must annotate return type: `def get_queryset(self) -> QuerySet[MyModel]:`
- Class-based views for complex logic, function-based for simple endpoints
- API views return JSON (DRF serializers); page views render Django templates
- Templates use HTMX for partial updates, Alpine.js for client-side interactivity
- All templates extend `templates/base/base.html`; HTMX fragments in `templates/<app>/fragments/`
- Models use `default_auto_field = "django.db.models.BigAutoField"`
- Every model: `__str__`, `class Meta` with `verbose_name`, `verbose_name_plural`, `ordering`, `db_table`
- `related_name` on every FK/M2M — pattern: `"<appname>_<field>"` or descriptive unique name
- No raw SQL — use Django ORM exclusively
- Business logic in `services.py` — views stay thin

## Build and Test

```powershell
# Windows — activate venv
& .\.venv\Scripts\Activate.ps1

# Install ALL dependencies (type stubs included in requirements.txt)
pip install -r requirements.txt

# Run migrations
& .\.venv\Scripts\python.exe manage.py migrate --settings=app.settings_dev

# Run development server
& .\.venv\Scripts\python.exe manage.py runserver --settings=app.settings_dev

# Quality gate — run ALL, must all pass before committing
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev

# Tests
& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-report=term-missing

# Type checking (Pyright is authoritative; mypy as secondary)
& .\.venv\Scripts\python.exe -m pyright apps/
```

```bash
# Linux/macOS
source .venv/bin/activate
pip install -r requirements.txt
ruff check . --fix && ruff format .
python manage.py check --settings=app.settings_dev
pytest --cov=apps --cov-report=term-missing
pyright apps/
```

## Conventions

- App config: every app has `apps.py` with `name = "apps.<appname>"` and `default_auto_field`
- URL namespaces: each app uses its own namespace in `app/urls.py`
- Admin views: `apps/admin/urls.py` imports 8 view modules directly (views_auth, views_content, views_distribution, views_extended, views_infrastructure, views_security, views_settings, views_users)
- Shared admin imports: `apps/admin/views_shared.py` — all admin view modules do `from .views_shared import *`
- Admin template rendering: `_render_admin(request, template, context, breadcrumbs)` helper — never call `render()` directly in admin views
- Settings split: `settings.py` (base), `settings_dev.py`, `settings_production.py`
- Security: CSRF on all mutating endpoints, HTTPS-only headers in production, `X_FRAME_OPTIONS = "DENY"`
- Celery tasks in `tasks.py` per app, broker is Redis
- Storage credentials in `storage_credentials/` (gitignored)
- All dissolved apps fully removed — **never reference dissolved app names in imports**
- For cross-app communication: use `apps.core.events.EventBus` or Django signals — never direct imports between apps
- Backend and frontend must be shipped in sync for each feature: domain model/service/API changes must include matching template/component/UX wiring in the same delivery window, and frontend behavior changes must be backed by canonical backend contracts
- For `apps/seo`, `apps/distribution`, and `apps/ads`, upgrades are in-place only: extend existing modules/data flows and update existing templates/components, never introduce parallel "v2/new/refactor" implementations
- New files are restricted by default: extend canonical files first; create new files only when architecture boundaries or proven split/performance needs require it
- Reusable components are mandatory when available in `templates/components/`; inline duplication of reusable UI patterns is forbidden
- Static assets must remain minimal and structured; split large CSS/JS files only when performance or maintainability requires it, otherwise no new static file creation
- No-regression completion gate: backend/frontend/static/database changes are only complete after quality checks pass and behavioral consistency is verified

## Database

- PostgreSQL 17 on localhost:5432 (dev) / configured via `DATABASE_URL` env var
- DB name: `appdb` (dev), configured via `.env`
- Dissolved app models use `db_table = "original_app_tablename"` in Meta — existing data preserved
- Migrations in each app's `migrations/` directory
- Always run `makemigrations` before pushing model changes

## API Design

- All endpoints under DRF with proper serializers
- Authentication: JWT via PyJWT + django-allauth for social auth
- Pagination: cursor-based for large datasets
- Versioning: URL prefix `/api/v1/`
- Error responses: consistent `{"error": "message", "code": "ERROR_CODE"}` format
- WAF rate limiting: `apps.security` (`RateLimitRule`, `BlockedIP`, `CrawlerRule`) — enforced at middleware level
- Download quota: `apps.firmwares` (`DownloadToken`) + `apps.devices` (`QuotaTier`) — enforced at download time
- These are two separate systems — never conflate them

---

## App Boundary Rules — Zero Tolerance

Apps MUST be self-contained, pluggable, and modular. Cross-app coupling is a critical violation.

### Allowed Cross-App References

| Pattern | Allowed | Example |
| --- | --- | --- |
| Admin views importing app models | **Yes** | `apps/admin/views_content.py` imports `apps.blog.models.Post` |
| `apps.core` infrastructure imported anywhere | **Yes** | `from apps.core.models import TimestampedModel` or `from apps.core.events.bus import event_bus` |
| `apps.site_settings` config imported anywhere | **Yes** | `from apps.site_settings.models import SiteSettings` |
| `apps.users.models.User` imported anywhere | **Yes** | FK references to `AUTH_USER_MODEL` or `settings.AUTH_USER_MODEL` |
| `apps.consent` decorators/middleware anywhere | **Yes** | `from apps.consent.decorators import consent_required` |
| URL `reverse()` in templates | **Yes** | `{% url 'firmwares:detail' pk=fw.pk %}` |
| Views importing models from multiple apps | **Yes** | Views are orchestrators — they wire data from multiple apps |

### FORBIDDEN Cross-App References

| Pattern | Violation | Fix |
| --- | --- | --- |
| App A imports App B's model in its models.py | **FORBIDDEN** | Use FK with `settings.AUTH_USER_MODEL` or abstract base |
| App A imports App B's service directly | **FORBIDDEN** | Use `apps.core.events.EventBus`, Celery tasks, or Django signals |
| Circular imports between apps | **CRITICAL** | Refactor into shared `apps.core` or use signals |

### Exception: Admin App

`apps/admin/` is the **only** app allowed to import models from ALL other apps. It is the central orchestration layer. All admin view modules (`views_content.py`, `views_security.py`, etc.) may freely import from any app.

---

## Reusable Components — Mandatory Usage

### Admin Components (`templates/components/_admin_*.html`)

| Component | File | Required For |
| --- | --- | --- |
| KPI Stat Card | `_admin_kpi_card.html` | ALL stat/metric cards on admin pages |
| Search Bar | `_admin_search.html` | ALL admin list page search inputs |
| Data Table | `_admin_table.html` | Sortable tables with pagination |
| Bulk Actions | `_admin_bulk_actions.html` | Multi-select action toolbars |

**Rule: NEVER inline KPI cards, search bars, or table sort logic. Always `{% include %}` the component.**

### End-User Components (`templates/components/_*.html`)

23 reusable components (4 admin + 19 enduser) for all pages. Full inventory:

| Component | File | Purpose |
| --- | --- | --- |
| Alert | `_alert.html` | Status messages (success, warning, error, info) |
| Badge | `_badge.html` | Status badges, tags, labels |
| Breadcrumb | `_breadcrumb.html` | Navigation breadcrumbs |
| Card | `_card.html` | Content cards with header/body/footer |
| Confirm Dialog | `_confirm_dialog.html` | Destructive action confirmation |
| Empty State | `_empty_state.html` | No-data placeholder with icon and CTA |
| Field Error | `_field_error.html` | Form field-level error display |
| Form Errors | `_form_errors.html` | Form-level error summary |
| Form Field | `_form_field.html` | Styled form field wrapper |
| Icon | `_icon.html` | Lucide SVG icon wrapper |
| Loading | `_loading.html` | Loading spinner / skeleton |
| Modal | `_modal.html` | Modal dialog overlay |
| Pagination | `_pagination.html` | Page navigation controls |
| Progress Bar | `_progress_bar.html` | Progress indicator |
| Search Bar | `_search_bar.html` | Public search input |
| Section Header | `_section_header.html` | Page section titles |
| Stat Card | `_stat_card.html` | Public statistics display |
| Theme Switcher | `_theme_switcher.html` | Dark/light/contrast toggle |
| Tooltip | `_tooltip.html` | Hover tooltip |

**Rule: NEVER duplicate UI patterns inline. Check `templates/components/` first — if a component exists, use it.**

See `.github/skills/admin-components/SKILL.md` and `.github/skills/enduser-components/SKILL.md` for full usage examples.

---

## Scraper Approval Workflow

Firmware data scraped by the OEM scraper is NEVER auto-inserted into the database. All scraped items go through admin review first.

**Workflow:** Scraper creates `IngestionJob` → status = `PENDING` → Admin reviews in Scraper page → **APPROVED** or **REJECTED** → Processing pipeline picks up APPROVED jobs → `DONE` or `FAILED`.

| Status | Meaning |
| --- | --- |
| `pending` | Awaiting admin review |
| `approved` | Admin approved — ready for processing |
| `rejected` | Admin rejected — will not be processed |
| `processing` | Being processed into firmware records |
| `done` | Successfully created firmware entry |
| `failed` | Processing failed (see `error` field) |
| `skipped` | Duplicate detected, auto-skipped |

Admin approval UI: `Admin Panel → Firmwares → Scraper → Pending Approval` section with individual and bulk approve/reject actions.

---

## Requirements Management — Zero Drift Policy

**`requirements.txt` is the single source of truth** for all Python dependencies. It must always reflect exactly what the project needs — nothing missing, nothing extra, nothing deprecated.

### Mandatory Rules

1. **Every `pip install` → update `requirements.txt`** — never install without recording
2. **Every direct import → listed in `requirements.txt`** — if any `.py` file imports a third-party package, it must be listed
3. **Every entry in `requirements.txt` → actually used** — imported in code, in `INSTALLED_APPS`, or used as a CLI tool
4. **Never remove without checking `Required-by:`** — run `pip show <pkg>` before removing; if another package depends on it, do NOT remove
5. **Type stubs in `requirements.txt`** — `django-stubs`, `djangorestframework-stubs`, `types-requests` etc. go in the file, not in separate install commands
6. **Pin version ranges** — use `>=min,<major_ceiling` (e.g., `Django>=5.2.9,<5.3`), never bare package names
7. **Never use `pip freeze > requirements.txt`** — curate manually with organized sections

### Verification Commands

```powershell
# Check for broken dependency chains
& .\.venv\Scripts\pip.exe check

# Check transitive deps before removing
& .\.venv\Scripts\pip.exe show <package-name>  # check "Required-by:" field

# Find outdated packages
& .\.venv\Scripts\pip.exe list --outdated --format=columns
```

### When Adding/Removing Packages

- **Adding**: Install → add to `requirements.txt` in correct section with version range → `pip check`
- **Removing**: Search codebase for imports → check `Required-by:` → remove from `requirements.txt` → uninstall → `pip check`
- **Dissolving an app**: Audit all imports from that app's `requirements` and remove packages no longer used by any remaining app

Full details: `.github/skills/requirements-management/SKILL.md`

---

## Common Mistakes — Lessons Learned

These are real issues encountered during development. Every agent MUST be aware of them.

1. **[Type] Django reverse FK managers** (e.g. `brand.models.filter(...)`) are not resolved by Pyright. Fix: `# type: ignore[attr-defined]` with a comment explaining the reverse manager name.
2. **[Type] `QuerySet.first()` returns `Model | None`** — passing this to a helper that types the param as `object` loses type info. Use `TYPE_CHECKING` import + proper type annotation.
3. **[Type] Never blanket `# type: ignore`** — always specify the error code: `[attr-defined]`, `[import-untyped]`, `[union-attr]`, etc.
4. **[Type] `ModelAdmin` requires type parameter** — `class MyAdmin(admin.ModelAdmin[MyModel]):` not just `admin.ModelAdmin`.
5. **[Frontend] Alpine.js `x-show` + CSS animations conflict** — if an element has both `x-show` and CSS `animate-in`, the animation class overrides the display:none, causing flicker. Remove animation classes on elements with `x-show`.
6. **[Frontend] All Alpine.js conditional elements must have `x-cloak`** — prevents flash of unstyled content (FOUC) during Alpine initialization.
7. **[Frontend] `--color-accent-text`** is WHITE in dark/light themes but BLACK in contrast theme. Never hardcode `text-white` on accent backgrounds — use the CSS custom property.
8. **[Frontend] HTMX fragments must NOT extend base templates** — fragments are injected into existing pages, so they must be standalone HTML snippets without `{% extends %}`.
9. **[Frontend] `string_if_invalid` in dev settings** helps catch missing template variables — set it to `"!!! MISSING: %s !!!"` in `settings_dev.py`.
10. **[Arch] WAF rate limits ≠ Download quotas** — two completely separate systems in two different apps. Never import `RateLimitRule` in firmware code or `DownloadToken` in security code.
11. **[Arch] Scraped data never auto-inserts** — always goes through `IngestionJob` → admin approval workflow.
12. **[Arch] Views are orchestrators** — they CAN import from multiple apps. Models and services must NOT cross app boundaries.
13. **[Arch] `apps.core` is NOT a shim** — it's a full infrastructure layer. Only `models.py` re-exports base models.
14. **[DB] Dissolved app models keep `db_table`** — e.g. `db_table = "crawler_guard_crawlerrule"` ensures existing data is preserved without data migration.
15. **[DB] Always `select_for_update()` on wallet transactions** — prevents race conditions on credit balance changes.
16. **[Frontend] Consent form views NEVER return JSON** — `accept_all`, `reject_all`, `accept` always return `HttpResponseRedirect` to `HTTP_REFERER`. Cookie is set on the redirect response. `fetch()` callers follow the redirect automatically and their `.then()` handler fires regardless. This eliminates the entire class of "raw JSON on blank screen" bugs. See `apps/consent/views.py` `_consent_done()` for the canonical pattern. For JSON consent API, use `consent/api/status/` and `consent/api/update/` (separate DRF endpoints).
17. **[Docs] Every new feature/app MUST be documented** in `README.md`, `AGENTS.md`, and `.github/copilot-instructions.md` before the task is considered complete.
18. **[Static] New static files are not the default solution** — extend existing static modules first; split only when measurable file-size/lag complexity warrants it.
19. **[Enterprise] Preserve operational guardrails** — keep performance budgets, observability, rollback readiness, and backward-compatible rollout patterns in scope for significant changes.

---

## Governance System

The platform uses a comprehensive AI governance system for automated code quality enforcement.

| Component | Location | Count |
| --- | --- | --- |
| Rules | `.claude/rules/` | 58 |
| Hooks | `.claude/hooks/` | 36 |
| Commands | `.claude/commands/` | 50 |
| Agents | `.github/agents/` | 44+ |
| Skills | `.github/skills/` | 27+ |

See [`GOVERNANCE.md`](GOVERNANCE.md) for full documentation.
See [`BREAKAGE_CHAINS.md`](BREAKAGE_CHAINS.md) for coupling chain analysis.
See [`AUDIT_CHECKLIST.md`](AUDIT_CHECKLIST.md) for post-implementation verification.
See [`DEPLOYMENT_CHECKLIST.md`](DEPLOYMENT_CHECKLIST.md) for pre-deploy checks.
See [`SECURITY_POLICY.md`](SECURITY_POLICY.md) for security reporting procedures.
