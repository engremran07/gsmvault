---
name: tw-dark-mode-media
description: "Media query dark mode: prefers-color-scheme. Use when: respecting OS-level dark mode preference, falling back when no user preference is stored."
---

# Media Query Dark Mode (prefers-color-scheme)

## When to Use

- Setting initial theme based on OS preference when no saved preference exists
- Understanding the relationship between OS preference and manual toggle
- Implementing accessible default theming

## Rules

1. **OS preference is the initial fallback** — only when no localStorage value exists
2. **Manual theme choice always overrides OS preference** — user intent wins
3. **Never rely solely on `prefers-color-scheme`** — our system uses `data-theme`
4. **Detect on first visit only** — once user picks a theme, persist that choice

## Patterns

### Initial Theme Detection with OS Fallback

```html
<script>
  (function() {
    let theme = localStorage.getItem('theme');
    if (!theme) {
      // Respect OS preference on first visit
      theme = window.matchMedia('(prefers-color-scheme: light)').matches
        ? 'light' : 'dark';
    }
    document.documentElement.setAttribute('data-theme', theme);
  })();
</script>
```

### Watching for OS Theme Changes

```javascript
// Only react to OS changes if user hasn't manually chosen
const mq = window.matchMedia('(prefers-color-scheme: dark)');
mq.addEventListener('change', (e) => {
  if (!localStorage.getItem('theme')) {
    const newTheme = e.matches ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', newTheme);
  }
});
```

### SCSS Media Query Fallback

```scss
/* Only as a safety net — data-theme should always be set */
@media (prefers-color-scheme: dark) {
  :root:not([data-theme]) {
    --color-bg-primary: #0f0f23;
    --color-text-primary: #e2e8f0;
  }
}

@media (prefers-color-scheme: light) {
  :root:not([data-theme]) {
    --color-bg-primary: #ffffff;
    --color-text-primary: #1e293b;
  }
}
```

### Combining with Alpine.js Theme Switcher

```html
<div x-data="{
  theme: localStorage.getItem('theme')
         || (window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark'),
  setTheme(t) {
    this.theme = t;
    document.documentElement.setAttribute('data-theme', t);
    localStorage.setItem('theme', t);
  }
}">
  <select x-model="theme" @change="setTheme(theme)"
          class="bg-[var(--color-bg-input)] text-[var(--color-text-primary)]
                 border border-[var(--color-border)] rounded px-2 py-1">
    <option value="dark">Dark</option>
    <option value="light">Light</option>
    <option value="contrast">High Contrast</option>
  </select>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| OS preference overriding saved choice | Ignores user intent | Check `localStorage` first |
| `@media (prefers-color-scheme)` as sole mechanism | No manual toggle, no contrast theme | Use `data-theme` system |
| No fallback when JS disabled | No theme set | CSS fallback with `:root:not([data-theme])` |

## Red Flags

- `prefers-color-scheme` used without checking localStorage first
- Missing fallback for contrast theme (OS has no contrast preference)
- Theme flash on page load due to async detection

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `templates/base/base.html` — theme initialization script
- `static/js/src/theme-switcher.js` — theme switching logic
