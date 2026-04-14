---
name: tw-animations-transitions
description: "Transition utilities: duration, easing, delay. Use when: adding hover effects, state change animations, smooth UI feedback."
---

# Transition Utilities

## When to Use

- Adding smooth hover/focus effects
- Transitioning between UI states (open/closed, active/inactive)
- Building micro-interactions for buttons, cards, links

## Rules

1. **Specify transition property** — `transition-colors`, `transition-transform`, not `transition-all`
2. **Standard durations** — 150ms fast, 200ms normal, 300ms slow
3. **Use `ease-out` for enter, `ease-in` for exit** — matches natural motion
4. **No transition on page load** — only on state changes (hover, click)
5. **Alpine.js `x-transition` for show/hide** — Tailwind transitions for hover/focus

## Patterns

### Button Hover Transition

```html
<button class="bg-[var(--color-accent)] text-[var(--color-accent-text)]
               px-4 py-2 rounded-lg font-medium
               transition-colors duration-200 ease-out
               hover:bg-[var(--color-accent-hover)]
               active:scale-95 transition-transform">
  Download
</button>
```

### Card Hover Effect

```html
<div class="rounded-lg border border-[var(--color-border)]
            bg-[var(--color-bg-secondary)] p-6
            transition-shadow duration-200 ease-out
            hover:shadow-lg hover:shadow-[var(--color-shadow)]">
  <h3 class="text-[var(--color-text-primary)]">Card Title</h3>
</div>
```

### Alpine.js Show/Hide Transitions

```html
<div x-data="{ open: false }">
  <button @click="open = !open"
          class="text-[var(--color-accent)] transition-colors duration-150
                 hover:text-[var(--color-accent-hover)]">
    Toggle
  </button>

  <div x-show="open"
       x-transition:enter="transition ease-out duration-200"
       x-transition:enter-start="opacity-0 -translate-y-2"
       x-transition:enter-end="opacity-100 translate-y-0"
       x-transition:leave="transition ease-in duration-150"
       x-transition:leave-start="opacity-100 translate-y-0"
       x-transition:leave-end="opacity-0 -translate-y-2"
       x-cloak
       class="mt-2 p-4 rounded-lg bg-[var(--color-bg-secondary)]">
    Dropdown content
  </div>
</div>
```

### Duration Reference

| Duration | Class | Use Case |
|----------|-------|----------|
| 75ms | `duration-75` | Micro-interactions (active states) |
| 150ms | `duration-150` | Fast feedback (hover colours) |
| 200ms | `duration-200` | Standard transitions (cards, buttons) |
| 300ms | `duration-300` | Larger changes (dropdowns, panels) |
| 500ms | `duration-500` | Page-level transitions (fade-in) |

### Easing Reference

| Easing | Class | Use Case |
|--------|-------|----------|
| `ease-out` | `ease-out` | Enter animations (decelerate) |
| `ease-in` | `ease-in` | Exit animations (accelerate) |
| `ease-in-out` | `ease-in-out` | Symmetric transitions |
| Linear | `ease-linear` | Progress bars, continuous motion |

### Link Hover with Underline

```html
<a href="#" class="text-[var(--color-accent)]
                   underline underline-offset-2 decoration-transparent
                   transition-colors duration-150
                   hover:decoration-[var(--color-accent)]">
  Animated underline
</a>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `transition-all` | Transitions unwanted properties | Specify: `transition-colors`, `transition-transform` |
| `duration-1000` on hover | Too slow, feels laggy | Max `duration-300` for UI feedback |
| Transitions on page load | Elements animate in awkwardly | Only on `:hover`, `:focus`, state changes |
| Missing easing function | Default `ease` may not feel right | Specify `ease-out` or `ease-in-out` |

## Red Flags

- `transition-all` used broadly (transitions everything including layout)
- Transition durations over 500ms on interactive elements
- No `x-cloak` on Alpine.js elements with transitions

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `.claude/rules/alpine-patterns.md` — Alpine transition rules
- `templates/components/_modal.html` — transition examples
