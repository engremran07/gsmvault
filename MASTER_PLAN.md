# Master Plan

> Strategic roadmap and agent orchestration for the firmware distribution platform.
> For architecture, code style, and conventions see [`AGENTS.md`](AGENTS.md).
> For developer workflow see [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

## 1. Executive Summary

Transform the platform from API-only backend into a full-stack Django platform with Django-served frontend. Eliminate the need for a separate frontend deployment (Next.js/React SPA), cutting hosting costs to near-zero for the frontend layer.

**Stack**: Django 5.2 Templates + Tailwind CSS v4 + Alpine.js v3 + HTMX v2 + Lucide Icons + SCSS + Multi-CDN

**Cost**: Zero additional hosting — Django serves everything. WhiteNoise for static files in production.

| Approach | Monthly Cost | Complexity |
| --- | --- | --- |
| Next.js + Vercel + API | $20–$200/mo (Vercel Pro) | High (2 deployments, CORS, JWT relay) |
| React SPA + S3/CDN | $5–$50/mo (CloudFront) | Medium (build pipeline, API proxy) |
| **Django Templates (this plan)** | **$0 extra** | **Low (single deployment)** |

---

## 2. Frontend Reference

All frontend architecture details are documented in [`AGENTS.md § Frontend Architecture`](AGENTS.md#frontend-architecture):

- Technology Stack (Tailwind v4, Alpine.js v3, HTMX v2, Lucide v0.460+, SCSS)
- Multi-CDN Fallback Strategy (jsDelivr → cdnjs → unpkg → local vendor)
- Theme System (Dark Tech, Light Professional, High Contrast)
- Template Hierarchy and HTMX View Patterns
- Component Library (23 reusable components)
- Static File Structure and Build Pipeline

### CDN Manifest

Library versions and integrity hashes are pinned in `static/vendor/cdn-manifest.json`:

| Library | Version | Pinned Major |
| --- | --- | --- |
| Tailwind CSS | 4.1.8 | `@4` |
| Alpine.js | 3.14.9 | `@3` |
| HTMX | 2.0.4 | `@2` |
| Lucide Icons | 0.468.0 | `@0.460` (pin to minor — breaking changes between minors) |

> **Critical**: Lucide uses `@latest` in some CDN URLs. Always pin to a specific version in production.

### Notification System

```javascript
// Alpine.js stores (static/js/src/notifications.js)
$store.notify.show(message, type, duration)  // Toast: success, error, warning, info
$store.confirm.ask(title, message)           // Promise-based confirmation dialog
```

- `_messages.html` auto-converts Django messages to toast notifications
- `_confirm_dialog.html` renders the confirm modal

### Anti-FOUC

All Alpine.js elements with `x-show` or `x-if` must include `x-cloak`. The global rule `[x-cloak] { display: none !important; }` is loaded inline in `<head>` before any script execution.

---

## 3. HTMX + Alpine.js Integration Patterns

### 3.1 HTMX for Server-Driven Updates

```html
<!-- Firmware search with live results -->
<input type="search"
       name="q"
       hx-get="/firmwares/search/"
       hx-trigger="keyup changed delay:300ms"
       hx-target="#search-results"
       hx-indicator="#search-spinner"
       placeholder="Search firmware...">

<div id="search-spinner" class="htmx-indicator">
  {% include "components/_loading.html" %}
</div>

<div id="search-results">
  {% include "firmwares/_search_results.html" %}
</div>
```

### 3.2 Alpine.js for Client-Side Interactivity

```html
<!-- Download button with ad gate -->
<div x-data="{ showAdGate: false, downloading: false }">
  <button @click="showAdGate = true"
          class="btn-primary"
          :disabled="downloading">
    <i data-lucide="download"></i>
    <span x-text="downloading ? 'Downloading...' : 'Download'"></span>
  </button>

  <template x-if="showAdGate">
    {% include "components/_modal.html" with title="Watch Ad to Download" %}
  </template>
</div>
```

### 3.3 Django View Pattern

```python
def firmware_search(request):
    query = request.GET.get("q", "")
    results = Firmware.objects.filter(name__icontains=query)[:20]
    if request.headers.get("HX-Request"):
        return render(request, "firmwares/_search_results.html", {"results": results})
    return render(request, "firmwares/search.html", {"results": results, "query": query})
```

---

## 4. Template & Static File Inventory

### 4.1 Full Template Tree

```text
templates/
  base/                     # Root layout fragments
    _base.html, _head.html, _scripts.html, _nav.html, _sidebar.html,
    _footer.html, _messages.html, _cdn_fallback.html
  layouts/                  # Page layouts
    default.html, dashboard.html, auth.html, minimal.html, admin.html
  components/               # 23 reusable partials (see AGENTS.md § Reusable Components)
  pages/                    # Static pages: home, about, terms, privacy, contact
  auth/                     # Auth flow: login, register, password_reset, mfa_setup, social_signup
  blog/                     # list, detail, category, tag
  devices/                  # list, detail, compare
  firmwares/                # list, detail, download gate, search
  shop/                     # list, detail, cart, checkout
  user/                     # dashboard, profile, settings, notifications, wallet, downloads, referrals, badges
  marketplace/              # list, detail, create
  bounty/                   # list, detail, submit
  admin_panel/              # dashboard, users, content, analytics, security, settings
  errors/                   # 400, 403, 404, 500, maintenance
  emails/                   # base_email, welcome, password_reset, notification, download_ready
```

### 4.2 Static File Tree

```text
static/
  css/src/                  # SCSS: main.scss, _variables, _reset, _base, _typography,
                            #   _components, _utilities, _animations, themes/{_dark,_light,_contrast}
  css/dist/                 # Compiled CSS (main.css, main.min.css)
  js/src/                   # JS: main.js, theme-switcher.js, ajax.js, cdn-fallback.js,
                            #   notifications.js, download.js, search.js,
                            #   components/{modal,table-sort,infinite-scroll,file-upload,clipboard}.js
  js/dist/                  # Minified bundle
  vendor/                   # cdn-manifest.json + local fallbacks (tailwindcss/, alpinejs/, htmx/, lucide/)
  img/                      # logo.svg, favicons, og-default.png, placeholder.svg, brands/
  fonts/                    # Inter (WOFF2), JetBrains Mono (WOFF2)
  icons/                    # sprite.svg
```

---

## 5. Build Pipeline

### 5.1 Development (Zero-Config)

CDN for all libraries — no build step, instant reload:

```html
<script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3/dist/cdn.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/htmx.org@2/dist/htmx.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/lucide@0.468.0/dist/umd/lucide.min.js"></script>
```

### 5.2 Production Build

```powershell
# Tailwind CLI standalone (no Node.js dependency)
.\tailwindcss.exe -i static/css/src/main.scss -o static/css/dist/main.css --minify
python manage.py collectstatic --noinput
```

### 5.3 CI/CD

```yaml
steps:
  - name: Build CSS
    run: npx @tailwindcss/cli -i static/css/src/main.scss -o static/css/dist/main.css --minify
  - name: Collect Static
    run: python manage.py collectstatic --noinput
  - name: Quality Gate
    run: |
      ruff check . --fix
      ruff format .
      python manage.py check --settings=app.settings_production
```

---

## 6. Agent Architecture

### 6.1 Overview

**8 Orchestrator Agents** — coordinate high-level workflows.
**31 Specialist Agents** — execute specific technical tasks.
**Total: 39 agents** in `.github/agents/`.

### 6.2 Orchestrator Agents (8)

| Agent | Role |
| --- | --- |
| `master-planner` | Top-level project coordinator. Reads all skills/agents, delegates work, tracks cross-cutting concerns. |
| `frontend-architect` | Frontend infrastructure: template hierarchy, static files, CDN strategy, theme design. |
| `backend-architect` | Backend infrastructure: model design, API architecture, service layer, Celery pipeline. |
| `quality-gatekeeper` | Quality enforcement: ruff, Pylance, Django check, tests. Fixes all problems. |
| `security-commander` | Security orchestrator: OWASP audits, WAF config, auth flows, CSP, dependency scanning. |
| `deployment-manager` | Production readiness: CI/CD, Docker, collectstatic, performance, monitoring. |
| `content-strategist` | Content pipeline: blog automation, SEO, i18n, email templates, social syndication. |
| `automation-pilot` | Repo maintenance: recursive cleanup, skill/agent updates, dependency management. |

### 6.3 Specialist Agents — Frontend (9)

| Agent | Role |
| --- | --- |
| `template-builder` | Django templates with proper inheritance, blocks, includes. |
| `tailwind-styler` | Tailwind CSS classes, responsive design, custom utilities. |
| `scss-architect` | SCSS structure, variables, mixins, theme compilation. |
| `alpine-developer` | Alpine.js components, stores, x-data patterns. |
| `htmx-developer` | HTMX attributes, server fragment patterns, partial updates. |
| `theme-designer` | CSS custom properties, theme switching, dark/light/contrast. |
| `icon-manager` | Lucide icon integration, SVG sprites, icon accessibility. |
| `responsive-designer` | Mobile-first layouts, breakpoints, touch interactions. |
| `accessibility-auditor` | WCAG AA/AAA compliance, ARIA, keyboard navigation, screen readers. |

### 6.4 Specialist Agents — Backend (8)

| Agent | Role |
| --- | --- |
| `api-endpoint` | REST API endpoints with DRF serializers. |
| `model-migration` | Django models and migrations. |
| `django-app-builder` | Scaffold new Django apps with templates. |
| `serializer-designer` | DRF serializers, nested serializers, validation. |
| `service-builder` | Business logic services, transaction management. |
| `celery-task-writer` | Async tasks, retry logic, beat schedules. |
| `signal-handler` | Django signals, post_save/pre_delete patterns. |
| `middleware-builder` | Custom middleware, request/response processing. |

### 6.5 Specialist Agents — Quality (5)

| Agent | Role |
| --- | --- |
| `test-writer` | pytest + factory-boy tests. |
| `code-reviewer` | Code quality review. |
| `integration-tester` | End-to-end workflow tests. |
| `type-checker` | Pylance/Pyright type safety, type ignore patterns. |
| `linter-fixer` | Ruff linting, formatting, import sorting. |

### 6.6 Specialist Agents — Security (3)

| Agent | Role |
| --- | --- |
| `security-audit` | OWASP security audit. |
| `auth-specialist` | JWT, allauth, MFA, session management. |
| `waf-configurator` | WAF rules, rate limits, IP blocking, crawler guard. |

### 6.7 Specialist Agents — Content/Commerce (6)

| Agent | Role |
| --- | --- |
| `seo-optimizer` | Meta tags, sitemaps, structured data, OG tags. |
| `i18n-translator` | Django i18n, translation files, locale management. |
| `email-designer` | Email templates, queue management, deliverability. |
| `shop-builder` | E-commerce: products, orders, checkout. |
| `wallet-manager` | Credits, transactions, referral rewards. |
| `affiliate-tracker` | Affiliate links, click tracking, commission attribution. |

---

## 7. Skill Architecture

### 7.1 Skills Inventory (15)

| Skill | Folder | Triggers |
| --- | --- | --- |
| `admin-components` | `.github/skills/admin-components/` | Admin KPI cards, search bars, tables, bulk actions |
| `admin-panel` | `.github/skills/admin-panel/` | Custom admin panel views, decorators, templates |
| `api-design` | `.github/skills/api-design/` | DRF endpoints, serializers, HTMX fragment patterns |
| `data-pipeline` | `.github/skills/data-pipeline/` | Data processing, ETL, batch operations |
| `django-app-scaffold` | `.github/skills/django-app-scaffold/` | Scaffold new Django apps with models, views, templates |
| `enduser-components` | `.github/skills/enduser-components/` | Reusable end-user components (card, modal, alert, etc.) |
| `frontend-templates` | `.github/skills/frontend-templates/` | Django templates, base layout, HTMX fragments |
| `htmx-alpine` | `.github/skills/htmx-alpine/` | HTMX + Alpine.js integration, live search, partial updates |
| `quality-gate` | `.github/skills/quality-gate/` | Ruff, Pylance, Django check, zero-tolerance enforcement |
| `security-check` | `.github/skills/security-check/` | OWASP, CSP, CDN integrity, template XSS patterns |
| `static-assets` | `.github/skills/static-assets/` | Static files, SCSS, JS, vendor, build pipeline |
| `static-cdn-registry` | `.github/skills/static-cdn-registry/` | CDN manifest, version pinning, fallback chain |
| `tailwind-theming` | `.github/skills/tailwind-theming/` | Tailwind CSS, themes, CSS variables, responsive |
| `testing` | `.github/skills/testing/` | pytest, factory-boy, fixtures, coverage |
| `web-scraping` | `.github/skills/web-scraping/` | OEM scraper, GSMArena sync, proxy pool, ingestion pipeline |

### 7.2 Agent ↔ Skill Matrix

| Agent | Primary Skill | Secondary Skills |
| --- | --- | --- |
| `template-builder` | `frontend-templates` | `tailwind-theming`, `enduser-components` |
| `tailwind-styler` | `tailwind-theming` | `static-assets` |
| `htmx-developer` | `htmx-alpine` | `frontend-templates` |
| `alpine-developer` | `htmx-alpine` | `frontend-templates` |
| `theme-designer` | `tailwind-theming` | `static-assets` |
| `quality-gatekeeper` | `quality-gate` | `security-check`, `testing` |
| `api-endpoint` | `api-design` | `htmx-alpine` |
| `django-app-builder` | `django-app-scaffold` | `frontend-templates` |
| `security-audit` | `security-check` | `quality-gate` |
| `test-writer` | `testing` | `quality-gate` |
| `automation-pilot` | `quality-gate` | `static-cdn-registry` |

### 7.3 Orchestrator ↔ Specialist Matrix

| Orchestrator | Manages |
| --- | --- |
| `master-planner` | All orchestrators |
| `frontend-architect` | template-builder, tailwind-styler, scss-architect, alpine-developer, htmx-developer, theme-designer, icon-manager, responsive-designer, accessibility-auditor |
| `backend-architect` | api-endpoint, model-migration, django-app-builder, serializer-designer, service-builder, celery-task-writer, signal-handler, middleware-builder |
| `quality-gatekeeper` | test-writer, code-reviewer, integration-tester, type-checker, linter-fixer |
| `security-commander` | security-audit, auth-specialist, waf-configurator |
| `deployment-manager` | Cross-cutting — works with all domains |
| `content-strategist` | seo-optimizer, i18n-translator, email-designer |
| `automation-pilot` | linter-fixer, type-checker (recursive repo maintenance) |

---

## 8. Implementation Phases

### Phase 1: Foundation ✅

Base template system, theme infrastructure, static file organization.

- `templates/base/` — Root layout fragments
- `templates/layouts/` — Page layouts (default, dashboard, auth, minimal)
- `templates/components/` — 23 reusable components
- `templates/errors/` — Error pages (400, 403, 404, 500)
- `static/css/src/` — SCSS structure with theme variables
- `static/js/src/` — JavaScript modules
- `static/vendor/` — CDN fallback copies
- `app/settings.py` — TEMPLATES dirs configured

### Phase 2: Core Pages ✅

Landing page, auth flow, error pages.

- `templates/pages/home.html` — Landing page with firmware search
- `templates/auth/` — Login, register, password reset, MFA
- `templates/errors/` — Styled error pages

### Phase 3: Content Pages ✅

Blog, devices, firmware catalog.

- `templates/blog/` — List, detail, category, tag views
- `templates/devices/` — Device catalog, detail, comparison
- `templates/firmwares/` — Firmware list, detail, download gate
- HTMX search and filtering

### Phase 4: User Dashboard (In Progress)

Authenticated user area.

- `templates/user/` — Dashboard, profile, settings, notifications, wallet
- Download history, referrals, gamification badges

### Phase 5: Commerce (Planned)

Shop, marketplace, bounty.

- `templates/shop/` — Product listing, cart, checkout
- `templates/marketplace/` — P2P listings
- `templates/bounty/` — Bounty board

### Phase 6: Admin Panel ✅

Custom admin dashboard (not Django admin).

- `templates/admin/` — 57 admin templates
- 8 view modules in `apps/admin/`
- KPI dashboard, user/content management, security monitoring

### Phase 7: Polish (Ongoing)

SEO, i18n, emails, performance.

- SEO metadata, Open Graph, structured data
- i18n translation setup
- Email templates
- Performance optimization

---

## 9. Recursive Automation

### 9.1 Quality Gate

Every agent runs this before AND after every task (see [`AGENTS.md § Quality Gate`](AGENTS.md#quality-gate--zero-tolerance-mandatory)):

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

### 9.2 Repo Health Checks

The `automation-pilot` agent performs periodic:

- **Dependency audit**: `pip-audit`, check for CVEs
- **Dead code detection**: `vulture apps/`
- **Import sorting**: `ruff check --select I --fix`
- **Migration drift**: Compare models vs. migrations
- **Agent/skill lint**: Validate frontmatter in all `.agent.md` and `SKILL.md` files
- **Type coverage**: `pyright --outputjson` summary
- **CDN version check**: Verify pinned versions against latest releases

### 9.3 Pre-Commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: ruff-check
        name: ruff check
        entry: ruff check --fix
        language: system
        types: [python]
      - id: ruff-format
        name: ruff format
        entry: ruff format
        language: system
        types: [python]
      - id: django-check
        name: django check
        entry: python manage.py check --settings=app.settings_dev
        language: system
        pass_filenames: false
```

---

## 10. Technology Decisions Log

| Decision | Chosen | Rejected | Rationale |
| --- | --- | --- | --- |
| Frontend framework | Django Templates + HTMX | React, Vue, Next.js | Zero extra hosting cost, full SEO, simpler auth |
| CSS framework | Tailwind CSS v4 | Bootstrap, Bulma | Utility-first, highly customizable, small production bundle |
| JS interactivity | Alpine.js + HTMX | React, Vue, jQuery | Lightweight, declarative, works with Django templates |
| Icon library | Lucide (v0.460+) | FontAwesome, Material | Open source, tree-shakeable, consistent design |
| Theme approach | CSS custom properties | Tailwind dark: variant only | Supports 3+ themes, instant switching, no rebuild |
| CDN strategy | Multi-CDN + local fallback | Single CDN | Resilience, zero downtime if one CDN fails |
| CSS preprocessor | SCSS | PostCSS, Less | Familiar, powerful nesting/variables, Django ecosystem |
| Build tool | Tailwind CLI standalone | webpack, Vite, esbuild | No Node.js dependency in production |
| AJAX approach | HTMX | fetch(), Axios | HTML-over-the-wire fits Django perfectly |
| Type checking | Pyright (authoritative) | mypy (secondary) | Better Django support, faster, VS Code integration |
| XSS sanitization | nh3 (Rust-based) | bleach (deprecated) | Faster, maintained, better security |
| Event bus | EventBus (apps.core) | Direct cross-app imports | Decoupled, testable, no circular imports |

---

## 11. Enterprise Platform Vision

Outperforms Easy Firmware Store Ultimate (Jaudi Softs) through:

| Capability | Implementation |
| --- | --- |
| Automated OEM scraping | `OEMSource`, `ScraperConfig` with multi-method fallback + proxy pool |
| Verified tester programme | `TrustedTester`, `VerificationReport` for firmware quality assurance |
| AI behaviour analytics | `BehaviorInsight` for anti-abuse and trust scoring |
| Dual ad-revenue model | Ad campaigns + full affiliate marketing (6+ networks) |
| Gamification | Points, badges, leaderboards for community engagement |
| Bounty system | Crowd-sourced firmware sourcing with rewards |
| P2P marketplace | User-to-user firmware/resource trading |
| Subscription wallet | Credits, referral rewards, ad-unlock gates |
| Download quota tiers | Free (ad-gated) → Registered → Subscriber → Premium |
