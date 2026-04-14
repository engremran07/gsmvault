---
name: alp-transitions-enter-leave
description: "Enter/leave transitions: x-transition. Use when: adding show/hide animations to x-show elements, dropdown open/close, modal appear/disappear, toast notifications."
---

# Alpine Enter/Leave Transitions

## When to Use

- Animating elements that toggle visibility with `x-show`
- Dropdown menus, modals, tooltips, notifications
- Any element that appears/disappears and needs smooth animation

## Patterns

### Basic x-transition (Shorthand)

```html
<div x-show="open" x-cloak x-transition>
  Content fades and scales in/out automatically.
</div>
```

### Custom Duration and Origin

```html
<div x-show="open" x-cloak
     x-transition.duration.200ms
     x-transition.origin.top>
  Dropdown content
</div>
```

### Full Enter/Leave Control

```html
<div x-show="open" x-cloak
     x-transition:enter="transition ease-out duration-200"
     x-transition:enter-start="opacity-0 -translate-y-2"
     x-transition:enter-end="opacity-100 translate-y-0"
     x-transition:leave="transition ease-in duration-150"
     x-transition:leave-start="opacity-100 translate-y-0"
     x-transition:leave-end="opacity-0 -translate-y-2">
  Animated panel
</div>
```

### Slide-In Sidebar

```html
<aside x-show="$store.sidebar.open" x-cloak
       x-transition:enter="transition ease-out duration-300"
       x-transition:enter-start="-translate-x-full"
       x-transition:enter-end="translate-x-0"
       x-transition:leave="transition ease-in duration-200"
       x-transition:leave-start="translate-x-0"
       x-transition:leave-end="-translate-x-full"
       class="fixed inset-y-0 left-0 w-64 z-40 bg-[var(--color-surface)]">
  <!-- sidebar -->
</aside>
```

### Fade-Only (No Scale)

```html
<div x-show="visible" x-cloak
     x-transition:enter="transition ease-out duration-300"
     x-transition:enter-start="opacity-0"
     x-transition:enter-end="opacity-100"
     x-transition:leave="transition ease-in duration-200"
     x-transition:leave-start="opacity-100"
     x-transition:leave-end="opacity-0">
  Fade content
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| CSS `animate-*` classes on `x-show` elements | Animation overrides `display:none`, causes flicker | Use `x-transition` exclusively |
| Missing `x-cloak` | Flash of content before Alpine hides it | Always add `x-cloak` |
| `x-transition` on `x-if` | `x-if` removes from DOM, no leave animation | Use `x-show` for animated toggle |
| Very long durations (>500ms) | Feels sluggish | Keep enter ≤300ms, leave ≤200ms |

## Red Flags

- `x-show` + Tailwind `animate-fade-in` or `animate-slide-up` — use `x-transition` instead
- Missing `x-cloak` on any `x-show` element
- `x-transition` without `x-show` (does nothing)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
