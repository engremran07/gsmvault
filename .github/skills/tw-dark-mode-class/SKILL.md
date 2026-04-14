---
name: tw-dark-mode-class
description: "Class-based dark mode: data-theme attribute switching. Use when: implementing theme persistence, setting up dark mode via data-theme, toggling themes via attribute."
---

# Class-Based Dark Mode (data-theme)

## When to Use

- Setting up theme switching infrastructure
- Understanding how the 3-theme system works
- Debugging theme-specific styling issues

## Rules

1. **Theme set via `data-theme` attribute on `<html>`** — not `class="dark"`
2. **3 themes: `dark` (default), `light`, `contrast`** — never add more without updating all tokens
3. **Persist theme in `localStorage`** — key: `theme`
4. **Apply theme before first paint** — inline script in `<head>` prevents flash
5. **All CSS custom properties scoped to `[data-theme="..."]`** — in `_themes.scss`

## Patterns

### HTML Structure

```html
<html lang="en" data-theme="dark">
<head>
  <!-- Apply theme before paint to prevent FOUC -->
  <script>
    (function() {
      const theme = localStorage.getItem('theme') || 'dark';
      document.documentElement.setAttribute('data-theme', theme);
    })();
  </script>
</head>
```

### SCSS Theme Scoping

```scss
/* static/css/src/_themes.scss */
[data-theme="dark"] {
  --color-bg-primary: #0f0f23;
  --color-text-primary: #e2e8f0;
  --color-accent-text: #ffffff;
}

[data-theme="light"] {
  --color-bg-primary: #ffffff;
  --color-text-primary: #1e293b;
  --color-accent-text: #ffffff;
}

[data-theme="contrast"] {
  --color-bg-primary: #000000;
  --color-text-primary: #ffffff;
  --color-accent-text: #000000; /* CRITICAL: BLACK, not white */
}
```

### Theme Toggle with Alpine.js

```html
<div x-data="{ theme: localStorage.getItem('theme') || 'dark' }">
  <button @click="theme = theme === 'dark' ? 'light' : 'dark';
                   document.documentElement.setAttribute('data-theme', theme);
                   localStorage.setItem('theme', theme)"
          class="p-2 rounded-lg bg-[var(--color-bg-secondary)]
                 text-[var(--color-text-primary)]">
    <span x-show="theme === 'dark'">🌙</span>
    <span x-show="theme === 'light'">☀️</span>
  </button>
</div>
```

### Theme-Conditional Content

```html
<!-- Show different icons based on theme -->
<div x-data="{ theme: document.documentElement.getAttribute('data-theme') }">
  <img x-show="theme === 'dark'" src="/static/img/logo-dark.svg" alt="Logo" x-cloak>
  <img x-show="theme === 'light'" src="/static/img/logo-light.svg" alt="Logo" x-cloak>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `class="dark"` on html | Not this project's pattern | `data-theme="dark"` |
| `dark:bg-gray-900` | Tailwind dark: prefix bypasses our system | `bg-[var(--color-bg-primary)]` |
| Theme script after CSS loads | Flash of wrong theme | Script in `<head>` before CSS |

## Red Flags

- Any use of Tailwind `dark:` prefix in templates
- Theme applied after DOM content loaded (causes flash)
- Missing `data-theme` attribute on `<html>`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `templates/base/base.html` — theme initialization script
- `static/css/src/_themes.scss` — theme definitions
- `templates/components/_theme_switcher.html` — theme switcher component
