---
name: tw-animations-gpu
description: "GPU-accelerated animations: transform, opacity, will-change. Use when: creating smooth animations, optimizing animation performance, avoiding layout thrashing."
---

# GPU-Accelerated Animations

## When to Use

- Creating smooth, performant animations
- Optimizing existing janky animations
- Animating elements that need 60fps

## Rules

1. **Only animate `transform` and `opacity`** — these are GPU-composited
2. **Never animate `width`, `height`, `top`, `left`** — causes layout recalculation
3. **`will-change` sparingly** — only on elements about to animate, remove after
4. **Alpine.js `x-show` conflicts with CSS animations** — remove animation classes from `x-show` elements
5. **Prefer `translate` over absolute positioning** — GPU-accelerated movement

## Patterns

### Fade In on Scroll

```html
<div class="opacity-0 translate-y-4 transition-all duration-500 ease-out"
     x-data="{ visible: false }"
     x-intersect="visible = true"
     :class="visible ? 'opacity-100 translate-y-0' : ''" x-cloak>
  Content fades in smoothly when scrolled into view.
</div>
```

### Scale on Hover (GPU-only properties)

```html
<div class="transform transition-transform duration-200 ease-out
            hover:scale-105 will-change-transform
            rounded-lg bg-[var(--color-bg-secondary)] p-4 cursor-pointer">
  Scales up on hover using GPU-composited transform.
</div>
```

### Slide In Panel

```html
<div x-data="{ open: false }">
  <button @click="open = true"
          class="bg-[var(--color-accent)] text-[var(--color-accent-text)]
                 px-4 py-2 rounded-lg">
    Open Panel
  </button>

  <!-- Backdrop -->
  <div x-show="open" @click="open = false"
       x-transition:enter="transition-opacity duration-300"
       x-transition:enter-start="opacity-0"
       x-transition:enter-end="opacity-100"
       x-transition:leave="transition-opacity duration-200"
       x-transition:leave-start="opacity-100"
       x-transition:leave-end="opacity-0"
       class="fixed inset-0 bg-black/50 z-40" x-cloak></div>

  <!-- Panel uses translate (GPU) not left/right -->
  <div x-show="open"
       x-transition:enter="transition-transform duration-300 ease-out"
       x-transition:enter-start="translate-x-full"
       x-transition:enter-end="translate-x-0"
       x-transition:leave="transition-transform duration-200 ease-in"
       x-transition:leave-start="translate-x-0"
       x-transition:leave-end="translate-x-full"
       class="fixed right-0 top-0 h-full w-80 z-50
              bg-[var(--color-bg-primary)] shadow-xl" x-cloak>
    Panel content
  </div>
</div>
```

### Performance-Safe Property List

| Property | GPU-Accelerated | Safe to Animate |
|----------|----------------|-----------------|
| `transform` (translate, scale, rotate) | ✅ Yes | ✅ Yes |
| `opacity` | ✅ Yes | ✅ Yes |
| `filter` (blur, brightness) | ✅ Yes | ⚠️ Moderate |
| `background-color` | ❌ No | ⚠️ For color transitions only |
| `width`, `height` | ❌ No | ❌ Avoid |
| `top`, `left`, `right`, `bottom` | ❌ No | ❌ Avoid |
| `margin`, `padding` | ❌ No | ❌ Avoid |
| `box-shadow` | ❌ No | ❌ Avoid (use opacity on pseudo-element) |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `animate-bounce` on `x-show` | Conflict — element never hides | Remove animation, use `x-transition` |
| Animating `width` or `height` | Layout thrashing, janky | Use `transform: scaleX/scaleY` |
| `will-change` on 20+ elements | Memory waste | Apply only before animation, remove after |
| `transition: all` | Animates everything including layout | `transition-transform`, `transition-opacity` |

## Red Flags

- Any CSS animation on `width`, `height`, `top`, `left`, `margin`, `padding`
- `will-change` applied permanently to many elements
- `x-show` combined with CSS `animate-*` classes (documented gotcha)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `.claude/rules/alpine-patterns.md` — Alpine.js animation rules
- `templates/components/_modal.html` — modal with GPU transitions
