---
name: tw-z-index-stacking-contexts
description: "Stacking context management: isolation, positioning. Use when: debugging z-index issues, preventing z-index leaks, understanding stacking order."
---

# Stacking Context Management

## When to Use

- Debugging z-index that doesn't work as expected
- Preventing child elements from escaping their container's layer
- Understanding why an overlay appears behind another element

## Rules

1. **`isolation: isolate` creates a new stacking context** — children can't escape
2. **`transform`, `opacity < 1`, `filter` create implicit stacking contexts** — be aware
3. **Keep stacking contexts minimal** — only isolate when needed
4. **Modal root must be at document body level** — not nested inside isolated contexts

## Patterns

### What Creates a Stacking Context

| CSS Property | Creates Context | Tailwind Class |
|-------------|----------------|----------------|
| `position: fixed/sticky` + `z-index` | ✅ Yes | `fixed z-40`, `sticky z-30` |
| `position: relative/absolute` + `z-index` | ✅ Yes | `relative z-10` |
| `opacity` < 1 | ✅ Yes | `opacity-90` |
| `transform` (any) | ✅ Yes | `transform`, `translate-*`, `scale-*` |
| `filter` / `backdrop-filter` | ✅ Yes | `blur-*`, `backdrop-blur-*` |
| `isolation: isolate` | ✅ Yes (intentional) | `isolate` |
| `will-change: transform/opacity` | ✅ Yes | `will-change-transform` |

### Isolating a Component

```html
<!-- Card with popover — isolate so popover z-index is scoped -->
<div class="isolate relative rounded-lg
            bg-[var(--color-bg-secondary)] p-4">
  <h3 class="text-[var(--color-text-primary)]">Component</h3>

  <!-- This z-20 is scoped within the isolated context -->
  <div class="absolute top-full left-0 z-20
              bg-[var(--color-bg-primary)] shadow-lg rounded-lg p-2">
    Popover content
  </div>
</div>
```

### Sidebar + Main Content Layering

```html
<div class="flex min-h-screen">
  <!-- Sidebar: its own stacking context via z-index -->
  <aside class="fixed inset-y-0 left-0 w-64 z-30
                bg-[var(--color-bg-secondary)]
                border-r border-[var(--color-border)]">
    Sidebar
  </aside>

  <!-- Main content: lower layer -->
  <main class="ml-64 relative z-0 flex-1">
    Content
  </main>
</div>
```

### Fixing "z-index doesn't work" Issues

```html
<!-- WRONG: z-50 inside a transformed parent — trapped -->
<div class="transform translate-x-0"> <!-- Creates stacking context! -->
  <div class="z-50"> <!-- z-50 is relative to parent, not viewport -->
    This won't appear above other page elements
  </div>
</div>

<!-- FIX: Move the overlay to body-level or remove unnecessary transform -->
<div class=""> <!-- No transform = no stacking context -->
  <div class="z-50 fixed inset-0">
    Now this works at the page level
  </div>
</div>
```

### Portal Pattern for Modals

```html
<!-- Modals should be rendered at body level, not nested inside components -->
<body>
  <div id="app">
    <!-- App content with various stacking contexts -->
  </div>

  <!-- Modal portal — outside all component stacking contexts -->
  <div id="modal-root" class="relative z-50">
    {% block modals %}{% endblock %}
  </div>
</body>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Modal inside `transform` parent | Trapped in stacking context | Move modal to body level |
| `isolate` on everything | Breaks expected z-index behaviour | Only isolate intentionally |
| `opacity-0` to hide + high z-index | Creates invisible stacking context | Use `hidden` or `x-show` |
| Random `z-[999]` to "fix" layering | Symptom, not cure | Fix the stacking context tree |

## Red Flags

- `z-[999]` or `z-[9999]` in code (indicates stacking context problem)
- Fixed/absolute modals nested inside transformed containers
- `opacity` or `transform` on containers that have overlays inside

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `templates/components/_modal.html` — modal at correct stacking level
- `templates/base/base.html` — body-level modal portal
