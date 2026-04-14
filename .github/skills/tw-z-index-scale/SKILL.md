---
name: tw-z-index-scale
description: "Z-index scale system: defined layers, stacking contexts. Use when: choosing z-index values, layering UI elements, managing overlay stacking."
---

# Z-Index Scale System

## When to Use

- Positioning overlays, dropdowns, modals, tooltips
- Resolving z-index conflicts between components
- Setting up a consistent stacking order

## Rules

1. **Use defined z-index tiers** — never arbitrary values like `z-[9999]`
2. **Modals above dropdowns above tooltips** — follow the layer hierarchy
3. **Define scale in CSS custom properties** — `_variables.scss`
4. **Toast notifications at highest layer** — always visible
5. **Avoid z-index on static elements** — only positioned elements need it

## Patterns

### Z-Index Scale

| Layer | Tailwind Class | Numeric | Use Case |
|-------|---------------|---------|----------|
| Base | `z-0` | 0 | Default content |
| Raised | `z-10` | 10 | Cards, elevated surfaces |
| Dropdown | `z-20` | 20 | Dropdown menus, popovers |
| Sticky | `z-30` | 30 | Sticky headers, sidebars |
| Fixed nav | `z-40` | 40 | Fixed navigation bar |
| Modal backdrop | `z-40` | 40 | Modal overlay background |
| Modal | `z-50` | 50 | Modal dialog |
| Tooltip | `z-50` | 50 | Tooltips, popovers over modals |
| Toast | `z-[60]` | 60 | Toast notifications |

### CSS Custom Properties

```scss
/* static/css/src/_variables.scss */
:root {
  --z-base: 0;
  --z-raised: 10;
  --z-dropdown: 20;
  --z-sticky: 30;
  --z-fixed: 40;
  --z-modal-backdrop: 40;
  --z-modal: 50;
  --z-tooltip: 50;
  --z-toast: 60;
}
```

### Fixed Navigation

```html
<nav class="fixed top-0 left-0 right-0 z-40
            bg-[var(--color-bg-primary)] border-b border-[var(--color-border)]">
  Navigation content
</nav>
```

### Modal with Backdrop

```html
<div x-data="{ open: false }">
  <!-- Backdrop: z-40 -->
  <div x-show="open" class="fixed inset-0 z-40 bg-black/50" x-cloak
       @click="open = false"></div>

  <!-- Modal: z-50 (above backdrop) -->
  <div x-show="open" class="fixed inset-0 z-50 flex items-center justify-center" x-cloak>
    <div class="bg-[var(--color-bg-primary)] rounded-xl shadow-xl
                max-w-md w-full mx-4 p-6">
      Modal content
    </div>
  </div>
</div>
```

### Toast Notification (highest layer)

```html
<div class="fixed top-4 right-4 z-[60]
            bg-[var(--color-status-success)] text-white
            px-4 py-3 rounded-lg shadow-lg">
  Download started successfully
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `z-[9999]` | Arbitrary, breaks scale | Use defined tier: `z-50` |
| `z-index` on non-positioned element | Has no effect | Add `relative` or `fixed` |
| Dropdown at `z-50` | Above modals | Use `z-20` for dropdowns |
| Modal without backdrop z-index | Click-through issues | Backdrop at `z-40`, modal at `z-50` |

## Red Flags

- Z-index values over 60 (scale violation)
- Z-index without a positioning context (`relative`, `absolute`, `fixed`, `sticky`)
- Dropdown menus appearing above modal dialogs

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `static/css/src/_variables.scss` — z-index scale definitions
- `templates/components/_modal.html` — modal z-index layer
- `templates/components/_tooltip.html` — tooltip z-index
