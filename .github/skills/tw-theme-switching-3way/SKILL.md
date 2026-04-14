---
name: tw-theme-switching-3way
description: "3-way theme toggle: dark/light/contrast with Alpine.js. Use when: building the theme switcher UI, implementing 3-way toggle, managing theme persistence."
---

# 3-Way Theme Switching

## When to Use

- Building or modifying the theme switcher component
- Adding theme-aware styling to new components
- Debugging theme switching behaviour

## Rules

1. **3 themes only: `dark`, `light`, `contrast`** — never add without full token coverage
2. **Use `{% include "components/_theme_switcher.html" %}`** — never inline theme toggle HTML
3. **Persist in `localStorage` key `theme`** — survives page reloads
4. **Apply before first paint** — inline `<head>` script
5. **`--color-accent-text`: WHITE (dark/light), BLACK (contrast)** — always use the token

## Patterns

### Theme Switcher Component

```html
<!-- templates/components/_theme_switcher.html -->
<div x-data="{
  theme: localStorage.getItem('theme') || 'dark',
  themes: [
    { value: 'dark', label: 'Dark', icon: 'moon' },
    { value: 'light', label: 'Light', icon: 'sun' },
    { value: 'contrast', label: 'Contrast', icon: 'eye' }
  ],
  setTheme(t) {
    this.theme = t;
    document.documentElement.setAttribute('data-theme', t);
    localStorage.setItem('theme', t);
  }
}" class="flex gap-1 rounded-lg bg-[var(--color-bg-secondary)] p-1">
  <template x-for="t in themes" :key="t.value">
    <button @click="setTheme(t.value)"
            :class="theme === t.value
              ? 'bg-[var(--color-accent)] text-[var(--color-accent-text)]'
              : 'text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)]'"
            class="px-3 py-1.5 rounded-md text-sm font-medium transition-colors"
            :aria-pressed="theme === t.value"
            :title="t.label"
            x-text="t.label" x-cloak>
    </button>
  </template>
</div>
```

### Head Script (FOUC prevention)

```html
<script>
  (function() {
    const t = localStorage.getItem('theme')
      || (window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark');
    document.documentElement.setAttribute('data-theme', t);
  })();
</script>
```

### Theme-Aware Component Example

```html
<div class="rounded-lg border-2
            border-[var(--color-border)]
            bg-[var(--color-bg-secondary)]
            shadow-[0_2px_8px_var(--color-shadow)]">
  <div class="p-4 border-b border-[var(--color-border)]">
    <h3 class="text-lg font-semibold text-[var(--color-text-primary)]">Title</h3>
  </div>
  <div class="p-4">
    <p class="text-[var(--color-text-secondary)]">Body content</p>
    <button class="mt-4 bg-[var(--color-accent)] text-[var(--color-accent-text)]
                   px-4 py-2 rounded-lg hover:bg-[var(--color-accent-hover)]">
      Action
    </button>
  </div>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Inline theme switcher HTML | Duplicates component | `{% include "components/_theme_switcher.html" %}` |
| `text-white` on accent | Breaks contrast theme | `text-[var(--color-accent-text)]` |
| Missing `x-cloak` on themed elements | FOUC on theme elements | Add `x-cloak` to all `x-show`/`x-if` |
| Theme set in `DOMContentLoaded` | Flash of wrong theme | Inline script in `<head>` |

## Red Flags

- Theme switcher not using the reusable component
- Hardcoded white/black text on accent backgrounds
- `localStorage` key not `theme` (inconsistent naming)
- Alpine.js `x-show`/`x-if` without `x-cloak`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `templates/components/_theme_switcher.html` — canonical component
- `static/css/src/_themes.scss` — all 3 theme definitions
- `.claude/rules/tailwind-tokens.md` — token rules
