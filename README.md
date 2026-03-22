# GSM Firmware Distribution Platform

Enterprise-grade Django 5.2 full-stack platform for firmware distribution. Django-served frontend with progressive enhancement — zero separate SPA, zero extra hosting cost. Built for scale with automated OEM scraping, AI analytics, subscription tiers, and a complete commerce ecosystem.

---

## Tech Stack

| Layer | Technology | Version |
| --- | --- | --- |
| **Framework** | Django | 5.2 |
| **Language** | Python | 3.12+ |
| **API** | Django REST Framework | Latest |
| **Auth** | JWT (PyJWT) + django-allauth | Social auth supported |
| **Database** | PostgreSQL | 17 |
| **Async** | Celery + Redis | Background tasks |
| **CSS** | Tailwind CSS (CDN dev / CLI prod) | v4 |
| **JS Reactivity** | Alpine.js | v3 |
| **JS Partial Updates** | HTMX | v2 |
| **Icons** | Lucide Icons | v0.460+ (pinned) |
| **CSS Preprocessor** | SCSS | Compiled locally |
| **Storage** | Google Cloud Storage / local | Abstracted |
| **Lint & Format** | Ruff | line-length 88, py312 |
| **Type Checking** | Pyright (authoritative) + mypy (secondary) | — |
| **XSS Prevention** | nh3 (Rust-based) | Replaced bleach |

---

## Features

### Firmware Lifecycle

- **Upload & distribution** — Official, Engineering, Readback, Modified, and Other firmware types
- **Brand/Model/Variant catalog** — Hierarchical device taxonomy with GSMArena spec sync
- **Verified tester programme** — `TrustedTester` and `VerificationReport` for quality assurance
- **Download gating** — HMAC-signed tokens, ad-gate unlock, hotlink protection, per-user rate limits
- **Download tiers** — Free (ad-gated) → Registered → Subscriber → Premium

### OEM Scraping

- **Automated ingestion** — `OEMSource`, `ScraperConfig` with multi-method fallback chain
- **Proxy pool** — Rotating proxies for resilient scraping
- **Admin approval workflow** — Scraped data never auto-inserts; goes through `IngestionJob` → approve/reject
- **Scheduled scraping** — Celery Beat with configurable intervals per source
- **GSMArena sync** — Device specs (`GSMArenaDevice`, `SyncRun`, `SyncConflict`)

### AI & Analytics

- **AI behaviour analytics** — `BehaviorInsight` for anomaly detection and trust scoring
- **Device fingerprinting** — `DeviceFingerprint`, `TrustScore`, bot detection
- **Traffic analytics** — Download, revenue, and affiliate performance tracking
- **AI providers** — Centralized facade (`CoreAiService`) with provider abstraction

### Commerce Ecosystem

- **Affiliate marketing** — Multi-network system (Amazon, AliExpress, CJ, ShareASale, Banggood)
- **Product matching** — Auto-match firmware device models to affiliate products
- **Shop** — Product listings, orders, checkout
- **Wallet & credits** — In-app credits, referral rewards, transaction history
- **P2P marketplace** — User-to-user firmware/resource trading
- **Bounty system** — Crowd-sourced firmware sourcing with rewards
- **Gamification** — Points, badges, leaderboards for community engagement
- **Referral programme** — Referral codes, reward tracking

### Content & Communication

- **Blog** — Posts with versioning, categories, feeds, AI editor, auto-publishing workflow
- **Static pages** — CMS pages (about, terms, privacy, etc.)
- **Comments** — User comments with moderation and consent gating
- **Notifications** — In-app, push, email (templates + queue), webhooks
- **Distribution** — Blog/social content syndication (Twitter, LinkedIn, WebSub)
- **SEO** — Full-featured SEO engine: metadata management, XML sitemaps with XSLT human-readable
  stylesheet, robots.txt, Open Graph, JSON-LD structured data, 301/302 redirect management,
  internal linking engine, AI-powered meta generation, SEO automation settings, sitemap index
  with per-section sitemaps (pages, blog, SEO entries, static URLs)

### Security

- **WAF rate limiting** — IP/path-based rules (`RateLimitRule`, `BlockedIP`)
- **Crawler guard** — Bot detection rules (`CrawlerRule`, `CrawlerEvent`)
- **CSP violation reporting** — `CSPViolationReport` for Content-Security-Policy monitoring
- **Security events** — Full audit log (`SecurityEvent`) for login failures, rate limits, abuse
- **MFA** — Multi-factor authentication support
- **CSRF** — Enforced on all mutating endpoints

### Frontend

- **3 themes** — Dark Tech (default), Light Professional, High Contrast (WCAG AAA)
- **23 reusable components** — Cards, modals, alerts, tables, pagination, tooltips, and more
- **Multi-CDN fallback** — jsDelivr → cdnjs → unpkg → local vendor
- **HTMX partial updates** — Server-driven HTML fragments, no full page reloads
- **Alpine.js reactivity** — Lightweight client-side interactivity
- **Toast notifications** — `$store.notify` for toasts, `$store.confirm` for confirmation dialogs

---

## Project Structure

```text
app/                  # Project config (settings, urls, wsgi, asgi, celery)
apps/                 # 30 Django apps — all consolidated, zero dissolved stubs
  # --- Infrastructure ---
  core/               # Enterprise infrastructure: caching, AI facade, sanitization,
                      #   throttling, event bus, signals, service abstractions, utils
  consent/            # Privacy enforcement: middleware, decorators, API, context processors,
                      #   consent scopes (functional, analytics, seo, ads), cookie banner
  site_settings/      # Global config (django-solo) + base models (Timestamped, SoftDelete, AuditFields)
  # --- Auth & Users ---
  users/              # User accounts, JWT auth, social auth, consent models, MFA
  user_profile/       # Extended profile (bio, social links, preferences, reputation)
  # --- Administration ---
  admin/              # Custom admin panel — 8 view modules, 57 templates, audit log
  # --- Devices ---
  devices/            # Device catalog, fingerprinting, trust scores, quota tiers, behavior insights
  # --- Firmware ---
  firmwares/          # Firmware files + brand/model catalog + verification + OEM scraper
                      #   + download gating + GSMArena sync
  # --- Content ---
  blog/               # Blog with versioning, categories, feeds, AI editor
  tags/               # Polymorphic tagging system
  comments/           # User comments with moderation
  pages/              # Static CMS pages
  ads/                # Ad campaigns + full affiliate marketing
  seo/                # Full-featured SEO engine: metadata (Metadata), structured data (SchemaEntry),
                      #   XML sitemaps (SitemapEntry) with XSLT stylesheet, 301/302 redirects (Redirect),
                      #   internal linking (LinkableEntity, LinkSuggestion), SEO automation settings
                      #   (SEOSettings, SeoAutomationSettings), AI-powered meta generation,
                      #   robots.txt, Open Graph, JSON-LD. Own admin panel section.
  # --- Commerce ---
  shop/               # Product listings, orders
  wallet/             # User wallet, credits, transactions
  marketplace/        # P2P firmware/resource marketplace
  bounty/             # Firmware bounty program
  referral/           # Referral program, codes, rewards
  gamification/       # Points, badges, leaderboards
  # --- Security ---
  security/           # WAF: rate limiting, IP blocking, crawler guard, CSP violations
  # --- Distribution ---
  distribution/       # Blog/social content syndication (NOT firmware distribution)
  # --- AI & Analytics ---
  ai/                 # AI providers, completions, prompt management
  analytics/          # Traffic, download, revenue, affiliate analytics
  # --- Communication ---
  notifications/      # In-app/push notifications + email templates/queue + webhooks
  # --- Operations ---
  storage/            # GCS/local file storage abstraction
  backup/             # Automated backup scheduling and restore
  moderation/         # Content moderation queue
  changelog/          # Changelog entries and version releases
  api/                # Top-level API gateway, versioning, health checks
  i18n/               # Internationalization utilities
templates/            # Django templates — base layouts, 23 components, HTMX fragments
static/               # CSS/SCSS, JS, vendor libs, images, fonts
scripts/              # Management and maintenance scripts
```

---

## Getting Started

### Prerequisites

- Python 3.12+
- PostgreSQL 17 with a database named `appdb` on `localhost:5432`
- Redis (for Celery task broker)

### Setup (Windows)

```powershell
# Create virtual environment (MUST be .venv, not venv)
python -m venv .venv
& .\.venv\Scripts\Activate.ps1

# Install dependencies + type stubs
pip install -r requirements.txt
pip install djangorestframework-stubs django-stubs types-requests

# Configure environment
# Copy .env.sample to .env and set DATABASE_URL, SECRET_KEY, etc.

# Run migrations
& .\.venv\Scripts\python.exe manage.py migrate --settings=app.settings_dev

# Create superuser
& .\.venv\Scripts\python.exe manage.py createsuperuser --settings=app.settings_dev

# Start development server
& .\.venv\Scripts\python.exe manage.py runserver --settings=app.settings_dev
```

### Setup (Linux / macOS)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install djangorestframework-stubs django-stubs types-requests
python manage.py migrate --settings=app.settings_dev
python manage.py createsuperuser --settings=app.settings_dev
python manage.py runserver --settings=app.settings_dev
```

---

## Quality Gate

Every change must pass all three checks with zero issues:

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix    # Lint
& .\.venv\Scripts\python.exe -m ruff format .          # Format
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev  # Django system check
```

Also verify:

- VS Code Problems tab shows zero warnings and zero errors
- `python -m pyright apps/` passes (Pyright is the authoritative type checker)

---

## Frontend Architecture

Django-served frontend — no separate SPA, no CORS issues, full SEO without hydration hacks.

### Template Hierarchy

```text
templates/
  base/               # Root layout: head, nav, footer, messages, CDN fallback
  layouts/            # Page layouts: default, dashboard, auth, admin, minimal
  components/         # 23 reusable partials (4 admin + 19 end-user)
  <app>/              # Per-app templates
    fragments/        # HTMX fragments for partial updates
```

### Theme System

Three switchable themes via CSS custom properties on `<html data-theme="dark|light|contrast">`:

| Theme | Description |
| --- | --- |
| **Dark Tech** | Default. Dark backgrounds, cyan/blue accents |
| **Light Professional** | White backgrounds, slate text, blue accents |
| **High Contrast** | WCAG AAA, strong borders, maximum readability |

Theme stored in `localStorage`, applied via Alpine.js store on page load. Switching is instant — no reload needed.

### Reusable Components (23)

**Admin** (4): `_admin_kpi_card`, `_admin_search`, `_admin_table`, `_admin_bulk_actions`

**End-user** (19): `_card`, `_modal`, `_alert`, `_confirm_dialog`, `_tooltip`, `_badge`, `_breadcrumb`, `_empty_state`, `_field_error`, `_form_errors`, `_form_field`, `_icon`, `_loading`, `_pagination`, `_progress_bar`, `_search_bar`, `_section_header`, `_stat_card`, `_theme_switcher`

All components are in `templates/components/` — always `{% include %}`, never inline.

---

## API

All endpoints under `/api/v1/` with DRF serializers, JWT authentication, and cursor-based pagination.

| Endpoint Group | Path | Description |
| --- | --- | --- |
| Firmware | `/api/v1/firmwares/` | CRUD, downloads, verification |
| Devices | `/api/v1/devices/` | Catalog, specs, fingerprinting |
| Blog | `/api/v1/blog/` | Posts, categories, feeds |
| Ads | `/api/v1/ads/` | Campaigns, affiliate tracking |
| Users | `/api/v1/users/` | Management, profiles, auth |
| Consent | `/api/v1/consent/` | Privacy consent status |
| Analytics | `/api/v1/analytics/` | Traffic, download metrics |

Error format: `{"error": "message", "code": "ERROR_CODE"}`

---

## Download Quota System

Two separate rate limiting systems — never conflate them:

### 1. WAF Security (`apps.security`)

IP/path-based hard limits at middleware level. Protects against DDoS, bot abuse, API scraping.

- `RateLimitRule` — Per-path rules (limit, window, action: throttle/block/log)
- `BlockedIP` — Permanent or timed IP blocks
- `CrawlerRule` — Bot/crawler detection and throttling

### 2. Download Quotas (`apps.firmwares` + `apps.devices`)

Per-user/tier limits enforced at download time. Powers the freemium model.

- `QuotaTier` — Tier config (daily/hourly limits, requires_ad, can_bypass_captcha)
- `DownloadToken` — Single-use HMAC-signed per-firmware per-user token
- `DownloadSession` — Tracks download lifecycle (bytes, start/complete/fail)
- `AdGateLog` — Ad watch tracking (video/banner/interstitial, credits earned)
- `HotlinkBlock` — Domain-level hotlinking protection

**Tiers**: Free (ad-gated) → Registered → Subscriber → Premium

---

## OEM Scraper

Device firmware scraper in `apps/firmwares/` with admin approval workflow.

### Workflow

1. `ScraperConfig` defines source, method, interval
2. Celery Beat triggers `ScraperRun`
3. Multi-method fallback chain attempts each scraping strategy
4. Scraped items create `IngestionJob` with status `PENDING`
5. Admin reviews in Admin Panel → Firmwares → Scraper → Pending Approval
6. Admin approves or rejects each item
7. Approved items are processed into firmware records

### Statuses

| Status | Meaning |
| --- | --- |
| `pending` | Awaiting admin review |
| `approved` | Ready for processing |
| `rejected` | Will not be processed |
| `processing` | Being created as firmware record |
| `done` | Successfully created |
| `failed` | Processing error (see `error` field) |
| `skipped` | Duplicate detected, auto-skipped |

### Management Command

```powershell
& .\.venv\Scripts\python.exe manage.py scrape_gsmarena --brand samsung --limit 50
```

---

## Admin Panel

Custom admin panel at `/admin-panel/` (separate from Django admin at `/admin/`).

### View Modules (8)

| Module | Domain |
| --- | --- |
| `views_auth` | Authentication, login, MFA |
| `views_content` | Blog, pages, comments, moderation |
| `views_distribution` | Firmware, brands, scraper, downloads |
| `views_extended` | Gamification, bounty, marketplace, referral |
| `views_infrastructure` | Analytics, backup, changelog, storage |
| `views_security` | WAF, rate limits, IP blocks, crawler guard, CSP |
| `views_settings` | Site settings, configuration |
| `views_users` | User management, profiles |

All views use the `_render_admin()` helper from `views_shared.py` — never call `render()` directly.

---

## Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `DJANGO_SETTINGS_MODULE` | `app.settings_dev` | Settings module |
| `DATABASE_URL` | `postgres://localhost:5432/appdb` | PostgreSQL connection |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis for Celery |
| `SECRET_KEY` | — | Django secret key |
| `DEBUG` | `True` (dev) | Debug mode |
| `ALLOWED_HOSTS` | `*` (dev) | Allowed hostnames |
| `GCS_BUCKET_NAME` | — | Google Cloud Storage bucket |
| `GCS_CREDENTIALS_FILE` | — | GCS service account JSON |

---

## Testing

```powershell
# Full test suite with coverage
& .\.venv\Scripts\python.exe -m pytest --cov=apps --cov-report=term-missing

# Specific app
& .\.venv\Scripts\python.exe -m pytest apps/firmwares/tests/ -v

# Type checking
& .\.venv\Scripts\python.exe -m pyright apps/
```

---

## Documentation

| Document | Purpose |
| --- | --- |
| [AGENTS.md](AGENTS.md) | Full architecture, code style, conventions (SSOT) |
| [MASTER_PLAN.md](MASTER_PLAN.md) | Strategy, agent/skill architecture, implementation phases |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Developer workflow, commit format, PR process |
| [.github/copilot-instructions.md](.github/copilot-instructions.md) | AI agent quick-reference card |

### AI Agent System

- **39 agents** in `.github/agents/` — 8 orchestrators + 31 specialists
- **15 skills** in `.github/skills/` — reusable knowledge packages
- Agents follow the quality gate, code style, and conventions in AGENTS.md

---

## License

Proprietary. All rights reserved.
