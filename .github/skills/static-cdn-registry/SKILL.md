---
name: static-cdn-registry
description: "CDN library registry and fallback chain. Use when: adding CDN libraries, checking CDN versions, configuring fallbacks, verifying external script integrity, updating library versions, adding new vendor dependencies."
---

# Static / CDN Registry Skill

## MANDATORY Rules

1. **Always pin versions** — never use `@latest` in production CDN URLs
2. **Always provide 3-tier fallback** — jsDelivr → cdnjs → unpkg → local vendor
3. **Always add `nonce="{{ request.csp_nonce }}"` and `crossorigin="anonymous"`** to all external scripts
4. **Always use `defer`** on Alpine.js and its plugins
5. **Never add new CDN dependencies without updating this registry**

---

## CDN Library Inventory

### Frontend Framework Libraries (6)

| # | Library | Version | CDN URL (jsDelivr Primary) | File | Purpose |
|---|---------|---------|---------------------------|------|---------|
| 1 | **Tailwind CSS** | v4 (browser) | `cdn.jsdelivr.net/npm/@tailwindcss/browser@4` | `_head.html:50` | Utility-first CSS framework (dev-only CDN, compiled in prod) |
| 2 | **HTMX** | v2 | `cdn.jsdelivr.net/npm/htmx.org@2/dist/htmx.min.js` | `_scripts.html:5` | HTML-over-the-wire partial page updates |
| 3 | **Alpine.js** | v3 | `cdn.jsdelivr.net/npm/alpinejs@3/dist/cdn.min.js` | `_scripts.html:46` | Lightweight client-side reactivity (must be LAST deferred script) |
| 4 | **Alpine.js Intersect** | v3 | `cdn.jsdelivr.net/npm/@alpinejs/intersect@3/dist/cdn.min.js` | `_scripts.html:41` | Scroll-triggered entrance animations (loaded BEFORE Alpine core) |
| 5 | **Chart.js** | v4 | `cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js` | `_scripts.html:28` | Analytics and dashboard charts |
| 6 | **Lucide Icons** | v0.468.0 | `cdn.jsdelivr.net/npm/lucide@0.468.0/dist/umd/lucide.min.js` | `_scripts.html:10` | SVG icon library (pin to minor — breaking changes between minors) |

### Google Services (4)

| # | Service | URL | File | Purpose | Conditional |
|---|---------|-----|------|---------|-------------|
| 7 | **Google Fonts** | `fonts.googleapis.com/css2?family=Inter:wght@300..900&family=JetBrains+Mono:wght@400..700&display=swap` | `_head.html:40` | Typography — Inter (body) + JetBrains Mono (code) | Always |
| 8 | **Google Analytics (GA4)** | `www.googletagmanager.com/gtag/js?id={ID}` | `_head.html:62` | Page analytics tracking | `{% if settings.google_analytics_id %}` |
| 9 | **Google Tag Manager** | `www.googletagmanager.com/gtm.js?id={ID}` | `_head.html:74` | Tag management container | `{% if settings.google_tag_manager_id %}` |
| 10 | **Google Indexing API** | Server-side only (googleapis.com) | `apps/distribution/` | Search engine URL submission | Backend only |

---

## Fallback Chain

Defined in `templates/base/_cdn_fallback.html`. Runs after primary CDN scripts load and checks if globals are defined.

### HTMX Fallback (3-tier + local)

| Tier | URL | Version |
|------|-----|---------|
| Primary | `cdn.jsdelivr.net/npm/htmx.org@2/dist/htmx.min.js` | @2 (semver range) |
| Fallback 1 | `cdnjs.cloudflare.com/ajax/libs/htmx/2.0.4/htmx.min.js` | 2.0.4 (pinned) |
| Fallback 2 | `unpkg.com/htmx.org@2/dist/htmx.min.js` | @2 (semver range) |
| Local | `{% static "vendor/htmx/htmx.min.js" %}` | Bundled copy |

### Alpine.js Fallback (3-tier + local)

| Tier | URL | Version |
|------|-----|---------|
| Primary | `cdn.jsdelivr.net/npm/alpinejs@3/dist/cdn.min.js` | @3 |
| Fallback 1 | `cdnjs.cloudflare.com/ajax/libs/alpinejs/3.14.9/cdn.min.js` | 3.14.9 (pinned) |
| Fallback 2 | `unpkg.com/alpinejs@3/dist/cdn.min.js` | @3 |
| Local | `{% static "vendor/alpinejs/alpine.min.js" %}` | Bundled copy |

### Lucide Icons Fallback (2-tier + local)

| Tier | URL | Version |
|------|-----|---------|
| Primary | `cdn.jsdelivr.net/npm/lucide@0.468.0/dist/umd/lucide.min.js` | 0.468.0 (pinned) |
| Fallback 1 | `unpkg.com/lucide@0.468.0/dist/umd/lucide.min.js` | 0.468.0 (pinned) |
| Local | `{% static "vendor/lucide/lucide.min.js" %}` | Bundled copy |

### NO Fallback Configured

| Library | Primary CDN | Risk |
|---------|------------|------|
| **Chart.js v4** | jsDelivr only | Admin charts break if jsDelivr is down |
| **Alpine.js Intersect** | jsDelivr only | Entrance animations stop working |
| **Tailwind CSS (browser)** | jsDelivr only | Dev-only, acceptable — compiled CSS used in prod |
| **Google Fonts** | Google only | Falls back to system fonts via CSS font-stack |

---

## Script Loading Order

Critical — Alpine.js must be loaded LAST so all stores are registered before auto-init:

```
1. HTMX               (immediate, no defer)
2. Lucide Icons        (immediate, no defer)
3. Lucide init         (inline, DOMContentLoaded)
4. CDN fallback        (inline, runs immediately)
5. Chart.js            (defer)
6. theme-switcher.js   (defer — Alpine store)
7. notifications.js    (defer — Alpine store)
8. admin-charts.js     (defer — Alpine store)
9. Alpine Intersect    (defer — plugin, before Alpine)
10. Alpine.js          (defer — MUST BE LAST)
```

---

## Adding a New CDN Library

1. Add primary `<script>` or `<link>` to `_scripts.html` or `_head.html`
2. Always include `nonce="{{ request.csp_nonce }}"` and `crossorigin="anonymous"`
3. Add fallback entries to `_cdn_fallback.html` with test function
4. Bundle a local copy in `static/vendor/<lib>/`
5. Update this SKILL.md with the new entry
6. Pin to a specific major version (`@4`, `@3`) — never use `@latest`

---

## Known Issues / Risks

| Issue | Severity | Location |
|-------|----------|----------|
| ~~Lucide pinned to `@latest`~~ — **RESOLVED**: pinned to `0.468.0` | ~~HIGH~~ | `_scripts.html:10`, `_cdn_fallback.html:42` |
| Chart.js has zero fallback — single point of failure | **MEDIUM** | `_scripts.html:28` |
| Alpine Intersect has zero fallback | **LOW** | `_scripts.html:41` |
| HTMX version mismatch: `@2` in primary vs `2.0.4` in cdnjs fallback | **LOW** | `_cdn_fallback.html:22` |
