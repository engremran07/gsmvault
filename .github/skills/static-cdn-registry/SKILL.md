---
name: static-cdn-registry
description: "Vendor library registry. Use when: adding vendor JS libraries, checking library versions, updating library versions, adding new vendor dependencies."
---

# Static / Vendor Library Registry Skill

## Strategy: Local-First

All frontend JS libraries are served from **local vendor files** in `static/vendor/`. No CDN loading in templates. This eliminates CDN latency, prevents cache-busting issues, and removes external dependencies for page rendering.

## MANDATORY Rules

1. **Always pin versions** — record exact version in `cdn-manifest.json`
2. **All vendor files in `static/vendor/<lib>/`** — never inline or load from CDN
3. **Always add `nonce="{{ request.csp_nonce }}"`** to all `<script>` tags
4. **Always use `defer`** on Alpine.js and its plugins
5. **Never add new vendor dependencies without updating this registry and `cdn-manifest.json`**

---

## Vendor Library Inventory

### Frontend Framework Libraries (6)

| # | Library | Version | Local Path | Template | Purpose |
|---|---------|---------|------------|----------|---------|
| 1 | **Tailwind CSS** | v4.1.8 | `vendor/tailwindcss/tailwind.min.js` | `_head.html` | Utility-first CSS framework (dev-only, compiled in prod) |
| 2 | **HTMX** | v2.0.4 | `vendor/htmx/htmx.min.js` | `_scripts.html` | HTML-over-the-wire partial page updates |
| 3 | **Alpine.js** | v3.14.9 | `vendor/alpinejs/alpine.min.js` | `_scripts.html` | Lightweight client-side reactivity (must be LAST deferred script) |
| 4 | **Alpine.js Intersect** | v3.14.9 | `vendor/alpinejs/intersect.min.js` | `_scripts.html` | Scroll-triggered entrance animations (loaded BEFORE Alpine core) |
| 5 | **Chart.js** | v4.4.7 | `vendor/chartjs/chart.umd.min.js` | `layouts/admin.html` | Analytics and dashboard charts (admin only) |
| 6 | **Lucide Icons** | v0.460.0 | `vendor/lucide/lucide.min.js` | `_scripts.html` | SVG icon library (pin to minor — breaking changes between minors) |

### Google Services (conditional, still external)

| # | Service | URL | File | Purpose | Conditional |
|---|---------|-----|------|---------|-------------|
| 7 | **Google Analytics (GA4)** | `www.googletagmanager.com/gtag/js?id={ID}` | `_head.html` | Page analytics tracking | `{% if settings.google_analytics_id %}` |
| 8 | **Google Tag Manager** | `www.googletagmanager.com/gtm.js?id={ID}` | `_head.html` | Tag management container | `{% if settings.google_tag_manager_id %}` |

> Google Analytics/GTM are the only external scripts — they cannot be self-hosted. They are conditionally loaded and only present when the admin configures tracking IDs.

---

## Fonts

Self-hosted WOFF2 variable fonts in `static/fonts/`. No Google Fonts CDN dependency.

| Font | File | Purpose |
|------|------|---------|
| Inter Variable | `fonts/inter/inter-variable.woff2` | Body text |
| JetBrains Mono Variable | `fonts/jetbrains-mono/jetbrains-mono-variable.woff2` | Code blocks |

---

## Script Loading Order

Critical — Alpine.js must be loaded LAST so all stores are registered before auto-init:

```
1. HTMX               (defer)
2. Lucide Icons        (defer)
3. Lucide init         (inline, DOMContentLoaded + htmx:afterSettle)
4. Vendor check        (inline, console.warn on failure)
5. Chart.js            (defer, admin only)
6. theme-switcher.js   (defer — Alpine store)
7. notifications.js    (defer — Alpine store)
8. admin-charts.js     (defer — Alpine store, admin only)
9. Alpine Intersect    (defer — plugin, before Alpine)
10. Alpine.js          (defer — MUST BE LAST)
```

---

## Adding a New Vendor Library

1. Download the minified JS/CSS file
2. Place in `static/vendor/<lib>/<file>.min.js`
3. Add `<script src="{% static 'vendor/<lib>/<file>.min.js' %}" nonce="{{ request.csp_nonce }}" defer></script>` to the appropriate template
4. Update `static/vendor/cdn-manifest.json` with library name, version, and local path
5. Update this SKILL.md with the new entry
6. Run quality gate

### Download Command

```powershell
& .\.venv\Scripts\python.exe -c "
import urllib.request, os
url = 'https://cdn.jsdelivr.net/npm/<package>@<version>/dist/<file>.min.js'
path = 'static/vendor/<lib>/<file>.min.js'
os.makedirs(os.path.dirname(path), exist_ok=True)
urllib.request.urlretrieve(url, path)
print(f'Downloaded {os.path.getsize(path):,} bytes')
"
```

---

## Upgrading a Library

1. Download the new version to `static/vendor/<lib>/`
2. Update the version in `cdn-manifest.json`
3. Update this SKILL.md
4. Test thoroughly — especially Lucide (breaking changes between minor versions)
