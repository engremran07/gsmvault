---
name: static-assets
description: "Static file management, SCSS compilation, JavaScript modules, images, fonts, vendor libraries, CDN fallback, build pipeline. Use when: organizing static files, adding CSS/JS, configuring CDN, bundling assets, managing vendor libraries, setting up fonts, optimizing images."
---

# Static Assets

## When to Use

- Adding or organizing CSS/SCSS files
- Adding or organizing JavaScript modules
- Managing vendor libraries (CDN fallbacks)
- Configuring fonts, images, icons
- Setting up the build pipeline
- Rebuilding compiled CSS after SCSS changes
- Optimizing static files for production

## Rules

1. **Source files in `static/<type>/src/`** — SCSS and JS source files
2. **Built files in `static/<type>/dist/`** — compiled/minified output
3. **Vendor files in `static/vendor/`** — local CDN fallback copies
4. **Images in `static/img/`** — SVG preferred for icons/logos
5. **Fonts in `static/fonts/`** — self-hosted for privacy, WOFF2 format
6. **Never edit `dist/` files directly** — always edit `src/` and rebuild (exception: manual rebuild when no SCSS compiler available)
7. **Pin CDN versions** — in `static/vendor/cdn-manifest.json`
8. **Use SRI hashes** — `integrity` attribute on CDN `<script>` and `<link>` tags
9. **Lazy load images** — `loading="lazy"` on all `<img>` tags below the fold
10. **Minify for production** — `--minify` flag on Tailwind CLI
11. **CSP nonce on all `<script>` tags** — `nonce="{{ request.csp_nonce }}"` (including CDN fallback scripts)
12. **After any SCSS change, rebuild `main.css`** — update all 3 themes synchronously
13. **NEVER use `text-white` on accent backgrounds** — use `text-[var(--color-accent-text)]` instead (white on dark/light, black on contrast)
14. **NEVER use `hover:opacity-90`** — use `hover:bg-[var(--color-accent-hover)]` for theme-aware hover
15. **`::selection` uses `var(--color-accent-text)`** — never hardcode `color: white` in selection styles

## CRITICAL: Keeping main.css in Sync

`static/css/dist/main.css` is the compiled CSS served to the browser. It MUST contain:

1. **`[x-cloak]` rule** — `[x-cloak] { display: none !important; }` at the top
2. **All 3 theme blocks** — `:root` / `[data-theme="dark"]`, `[data-theme="light"]`, `[data-theme="contrast"]`
3. **Every CSS variable from `_variables.scss`** — mirrored in all 3 themes (including `--color-accent-text`)
4. **Cross-browser resets** — `text-size-adjust` vendor prefixes, `img { max-width: 100%; height: auto; }`
5. **Font declarations** — `body { font-family: var(--font-sans); }`, `code { font-family: var(--font-mono); }`
6. **All animation keyframes** — from `_animations.scss` (13+ keyframes)
7. **Enhanced button system** — `.btn-primary` with `color: var(--color-accent-text)`, `.btn-danger`, `.focus-ring`
8. **Glass morphism** — `.glass` class with per-theme variants (dark backdrop blur, light blur, contrast solid border)
9. **Interaction utilities** — `.hover-lift`, `.hover-glow`, `.btn-press`, `.stagger-children`, `.skeleton`

### Key Tokens to Keep in Sync Across All 3 Themes

| Token | Dark | Light | Contrast |
| --- | --- | --- | --- |
| `--color-accent` | `#3b82f6` | `#2563eb` | `#ffff00` |
| `--color-accent-hover` | `#2563eb` | `#1d4ed8` | `#e6e600` |
| `--color-accent-text` | `#ffffff` | `#ffffff` | `#000000` |
| `--color-accent-soft` | `rgba(59,130,246,0.15)` | `rgba(37,99,235,0.1)` | `rgba(255,255,0,0.2)` |
| `--shadow-xl` | `0 20px 25px...` | `0 20px 25px...` | `none` |

### Animation Keyframes Inventory

fadeIn, fadeOut, slideUp, slideDown, slideInRight, slideOutRight, slideInLeft, scaleIn, scaleOut, shake, pulse, bounce, spin, float, ripple, progressCountdown, shimmer

### Rebuild process
When SCSS sources change, rebuild `main.css` to match. Ensure every `--color-*` variable exists in all 3 themes. Verify `--color-accent-text` is set correctly (white for dark/light, black for contrast).

## Directory Structure

```text
static/
  css/
    src/                    # SCSS source files
      main.scss             # Entry point (imports all partials)
      _variables.scss       # CSS custom properties — dark theme (source of truth)
      _reset.scss           # CSS reset / normalize
      _base.scss            # Base element styles
      _typography.scss      # Font faces, headings, text
      _components.scss      # Component-specific styles
      _utilities.scss       # Custom utilities beyond Tailwind
      _animations.scss      # Transitions, keyframes
      themes/
        _dark.scss           # No-op (dark = :root default in _variables.scss)
        _light.scss          # Light theme variable overrides
        _contrast.scss       # High contrast variable overrides
    dist/                   # Compiled output
      main.css              # Full compiled CSS (includes all themes + resets + animations)
      main.min.css          # Minified for production
  js/
    src/                    # JavaScript source modules
      main.js               # Entry point
      theme-switcher.js     # Alpine store: $store.theme (dark/light/contrast toggle + localStorage)
      ajax.js               # Fetch wrapper with CSRF token
      cdn-fallback.js       # Multi-CDN fallback loader
      notifications.js      # Alpine stores: $store.notify (toasts) + $store.confirm (dialogs)
      download.js           # Download flow management (ad gate, progress)
      search.js             # Search autocomplete
      components/
        modal.js            # Modal behavior
        table-sort.js       # Table column sorting
        infinite-scroll.js  # HTMX infinite scroll helper
        file-upload.js      # Upload with progress bar
        clipboard.js        # Copy to clipboard
    dist/                   # Minified output
      main.min.js
  img/
    logo.svg                # Main logo (theme-aware)
    logo-light.svg          # Light variant
    favicon.ico
    favicon-32.png
    favicon-16.png
    apple-touch-icon.png
    og-default.png          # Open Graph default
    placeholder.svg         # Image placeholder
    brands/                 # OEM brand logos
  fonts/
    inter/                  # Inter (primary sans-serif)
      inter-var.woff2
    jetbrains-mono/         # JetBrains Mono (code)
      jetbrains-mono-var.woff2
  vendor/
    cdn-manifest.json       # CDN URLs + versions + integrity hashes
    tailwindcss/
      tailwind.min.js       # Local fallback for Tailwind browser
    alpinejs/
      alpine.min.js         # Local fallback for Alpine.js
    htmx/
      htmx.min.js           # Local fallback for HTMX
    lucide/
      lucide.min.js         # Local fallback for Lucide
  icons/
    sprite.svg              # Common icon SVG sprite
```

## SCSS Architecture

```scss
// static/css/src/main.scss — Entry point
@use 'variables';       // CSS custom properties for dark theme (default)
@use 'reset';           // CSS reset / normalize
@use 'base';            // Base element styles
@use 'typography';      // Font faces, headings, text
@use 'components';      // Component-specific styles
@use 'utilities';       // Custom utilities beyond Tailwind
@use 'animations';      // Transitions, keyframes
@use 'themes/light';    // Light theme overrides
@use 'themes/contrast'; // Contrast theme overrides
```

## JavaScript Modules

### Key Alpine.js Stores

| Store | File | Purpose |
| --- | --- | --- |
| `$store.theme` | `theme-switcher.js` | Theme switching + localStorage |
| `$store.notify` | `notifications.js` | Toast notifications (success/error/warning/info) |
| `$store.confirm` | `notifications.js` | Async confirmation dialogs |

All stores registered via `alpine:init` event listener — loaded in `_scripts.html` with CSP nonce.

### CSRF-Aware Fetch

```javascript
// static/js/src/ajax.js
export function csrfFetch(url, options = {}) {
  const csrfToken = document.querySelector('[name=csrfmiddlewaretoken]')?.value
    || document.cookie.match(/csrftoken=([^;]+)/)?.[1];
  return fetch(url, {
    ...options,
    headers: {
      'X-CSRFToken': csrfToken,
      'X-Requested-With': 'XMLHttpRequest',
      ...options.headers,
    },
  });
}
```

## CDN Fallback Strategy

Load order: jsDelivr → cdnjs → unpkg → local vendor. All scripts must have CSP nonce.

```html
{# _scripts.html — each CDN script has nonce #}
<script src="https://cdn.jsdelivr.net/npm/alpinejs@3" nonce="{{ request.csp_nonce }}" defer></script>
<script src="https://cdn.jsdelivr.net/npm/htmx.org@2" nonce="{{ request.csp_nonce }}"></script>
<script src="https://cdn.jsdelivr.net/npm/lucide@0.468.0/dist/umd/lucide.min.js" nonce="{{ request.csp_nonce }}"></script>
```

## Build Pipeline

```powershell
# Development: CDN-only, no build needed

# Production build:
# 1. Compile SCSS → main.css (or manually rebuild main.css when SCSS sources change)
# 2. Build Tailwind
.\tailwindcss.exe -i static/css/src/main.scss -o static/css/dist/main.css --minify

# 3. Collect static files
python manage.py collectstatic --noinput
```

## Django Settings

```python
# app/settings.py
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_DIRS = [BASE_DIR / "static"]

# Production
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"
```

## Admin JS Module

`static/js/src/admin.js` is the admin-only JavaScript module loaded exclusively in `layouts/admin.html`. It provides:

### Sidebar Persistence

```javascript
// Read/write sidebar state to localStorage
const SIDEBAR_KEY = 'admin-sidebar-open';
function getSidebarState() {
  return JSON.parse(localStorage.getItem(SIDEBAR_KEY) ?? 'true');
}
```

### Ctrl+K Command Search

```javascript
document.addEventListener('keydown', (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
    e.preventDefault();
    document.getElementById('admin-command-search')?.focus();
  }
});
```

### Data-Confirm Pattern

```javascript
// Any element with data-confirm triggers $store.confirm before action
document.addEventListener('click', async (e) => {
  const el = e.target.closest('[data-confirm]');
  if (!el) return;
  e.preventDefault();
  const msg = el.getAttribute('data-confirm');
  const ok = await Alpine.store('confirm').ask('Confirm', msg);
  if (ok) {
    if (el.tagName === 'A') window.location = el.href;
    else if (el.form) el.form.submit();
  }
});
```

### Bulk Select Helpers

```javascript
// Wire up data-select-all / data-select-row checkboxes
function initBulkSelect(container) {
  const selectAll = container.querySelector('[data-select-all]');
  const rows = () => container.querySelectorAll('[data-select-row]');
  if (!selectAll) return;
  selectAll.addEventListener('change', () => {
    rows().forEach(cb => { cb.checked = selectAll.checked; });
  });
}
```

## Frontend/Admin Separation

JavaScript modules are split between shared (loaded everywhere) and admin-only:

| Module | Loaded In | Purpose |
| --- | --- | --- |
| `main.js` | `base/_scripts.html` | Global entry point |
| `notifications.js` | `base/_scripts.html` | `$store.notify`, `$store.confirm` |
| `theme-switcher.js` | `base/_scripts.html` | `$store.theme` |
| `cdn-fallback.js` | `base/_scripts.html` | Multi-CDN loader |
| `ajax.js` | `base/_scripts.html` | CSRF-aware fetch wrapper |
| `admin.js` | `layouts/admin.html` | Sidebar, Ctrl+K, data-confirm, bulk select |

Admin JS is loaded via `{% block extra_js %}` in `layouts/admin.html`:

```html
{% block extra_js %}
  <script src="{% static 'js/src/admin.js' %}" nonce="{{ request.csp_nonce }}" defer></script>
{% endblock %}
```

## SCSS Organization

Admin-specific component styles live in `static/css/src/_admin.scss`:

```scss
// static/css/src/_admin.scss
// Admin-specific component styles — imported in main.scss

.admin-sidebar-link { /* ... */ }
.admin-stat-card { /* ... */ }
.admin-table { /* ... */ }
.admin-badge { /* ... */ }
.admin-badge-success { /* ... */ }
.admin-badge-danger { /* ... */ }
.admin-badge-warning { /* ... */ }
.admin-badge-info { /* ... */ }
.admin-toggle { /* ... */ }
.admin-input { /* ... */ }
```

Add to `main.scss`:

```scss
@use 'admin';  // Admin-specific component styles
```

This keeps admin styles isolated, preventing them from bloating the public frontend CSS when code-split in the future.

## Procedure

1. Place source files in correct `src/` directory
2. Follow naming conventions (underscored partials for SCSS)
3. Update `main.scss` or `main.js` to import new modules
4. If SCSS changed, rebuild `main.css` — ensure all 3 themes are in sync
5. Ensure CSP nonce on every `<script>` tag (CDN and local)
6. Pin vendor versions in `cdn-manifest.json`
7. Test CDN fallback works (disable network, check local loads)
8. Build for production (Tailwind CLI + collectstatic)
9. Run quality gate
