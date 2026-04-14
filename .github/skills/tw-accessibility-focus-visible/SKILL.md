---
name: tw-accessibility-focus-visible
description: "Focus-visible: keyboard focus styles, outline management. Use when: styling keyboard focus indicators, managing focus rings, ensuring keyboard navigability."
---

# Focus-Visible Styles

## When to Use

- Styling keyboard focus indicators on interactive elements
- Ensuring all interactive elements are keyboard-navigable
- Distinguishing between mouse clicks and keyboard focus
- Building accessible navigation components

## Rules

1. **`focus-visible:` over `focus:`** — only shows for keyboard users, not mouse clicks
2. **Never `outline: none` without replacement** — removes keyboard accessibility
3. **Focus ring uses accent colour** — `focus-visible:ring-[var(--color-accent)]`
4. **Ring offset matches background** — `ring-offset-[var(--color-bg-primary)]`
5. **All interactive elements must be focusable** — buttons, links, inputs, custom controls

## Patterns

### Standard Focus Ring

```html
<!-- Button with keyboard-only focus ring -->
<button class="bg-[var(--color-accent)] text-[var(--color-accent-text)]
               px-4 py-2 rounded-lg font-medium
               focus:outline-none
               focus-visible:ring-2
               focus-visible:ring-[var(--color-accent)]
               focus-visible:ring-offset-2
               focus-visible:ring-offset-[var(--color-bg-primary)]">
  Download
</button>
```

### Link Focus Style

```html
<a href="/firmwares/"
   class="text-[var(--color-accent)]
          hover:text-[var(--color-accent-hover)]
          focus:outline-none
          focus-visible:ring-2
          focus-visible:ring-[var(--color-accent)]
          focus-visible:rounded-sm">
  View Firmwares
</a>
```

### Card as Focusable Element

```html
<a href="{{ device.get_absolute_url }}"
   class="block rounded-lg p-4
          bg-[var(--color-bg-secondary)]
          border border-[var(--color-border)]
          hover:border-[var(--color-accent)]
          focus:outline-none
          focus-visible:ring-2
          focus-visible:ring-[var(--color-accent)]
          focus-visible:ring-offset-2
          focus-visible:ring-offset-[var(--color-bg-primary)]
          transition-colors duration-200">
  <h3 class="text-[var(--color-text-primary)]">{{ device.name }}</h3>
</a>
```

### Custom Focus for Dark/Contrast Themes

```scss
/* static/css/src/_accessibility.scss */
/* Enhance focus ring in contrast theme */
[data-theme="contrast"] {
  *:focus-visible {
    outline: 3px solid var(--color-accent) !important;
    outline-offset: 2px;
  }
}
```

### Skip to Content Link

```html
<!-- First focusable element in the page -->
<a href="#main-content"
   class="sr-only focus:not-sr-only
          fixed top-4 left-4 z-[70]
          bg-[var(--color-accent)] text-[var(--color-accent-text)]
          px-4 py-2 rounded-lg font-medium
          focus:outline-none focus-visible:ring-2
          focus-visible:ring-[var(--color-accent)]">
  Skip to main content
</a>
```

### Focus Trap for Modals

```html
<div x-data="{ open: false }" @keydown.escape="open = false">
  <button @click="open = true"
          class="focus:outline-none focus-visible:ring-2
                 focus-visible:ring-[var(--color-accent)]">
    Open Modal
  </button>

  <div x-show="open" x-trap.noscroll="open"
       role="dialog" aria-modal="true"
       class="fixed inset-0 z-50 flex items-center justify-center" x-cloak>
    <div class="bg-[var(--color-bg-primary)] rounded-xl p-6 max-w-md w-full
                shadow-xl">
      <h2 class="text-lg font-bold text-[var(--color-text-primary)]">Modal</h2>
      <button @click="open = false"
              class="mt-4 bg-[var(--color-accent)] text-[var(--color-accent-text)]
                     px-4 py-2 rounded-lg
                     focus:outline-none focus-visible:ring-2
                     focus-visible:ring-[var(--color-accent)]">
        Close
      </button>
    </div>
  </div>
</div>
```

### Interactive Element Focus Checklist

| Element | Requires Focus | Pattern |
|---------|---------------|---------|
| `<button>` | ✅ Built-in | Add `focus-visible:ring-2` |
| `<a href>` | ✅ Built-in | Add `focus-visible:ring-2` |
| `<input>` | ✅ Built-in | Add `focus-visible:ring-2` |
| `<select>` | ✅ Built-in | Add `focus-visible:ring-2` |
| `<div @click>` | ❌ Not focusable | Add `tabindex="0"` + `role="button"` + `@keydown.enter` |
| Custom toggles | ❌ Needs tab index | Use `sr-only` checkbox + visible label |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `outline: none` with no replacement | Keyboard users can't see focus | Add `focus-visible:ring-2` |
| `focus:ring-*` instead of `focus-visible:` | Shows on mouse click too | Use `focus-visible:` prefix |
| `tabindex="-1"` on interactive elements | Removes from tab order | Remove or use `tabindex="0"` |
| `<div @click>` without keyboard handling | Not keyboard accessible | Add `tabindex="0"` + `@keydown.enter` |
| Ring offset not matching page background | Ugly gap colour | `ring-offset-[var(--color-bg-primary)]` |

## Red Flags

- `outline: none` or `outline: 0` without a visible focus replacement
- Interactive elements without any focus styling
- `<div>` or `<span>` with click handlers but no `tabindex` or `role`
- Missing skip-to-content link on pages with complex navigation

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `templates/base/base.html` — skip-to-content link
- `templates/components/_modal.html` — modal focus trap
- `static/css/src/_themes.scss` — theme focus overrides
