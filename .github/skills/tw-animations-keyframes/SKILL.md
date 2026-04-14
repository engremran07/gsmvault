---
name: tw-animations-keyframes
description: "Custom keyframe animations with Tailwind. Use when: creating custom animations beyond transitions, pulse/spin effects, complex multi-step animations."
---

# Custom Keyframe Animations

## When to Use

- Creating multi-step animations (not simple transitions)
- Building loading spinners, pulse effects, shimmer animations
- Defining reusable animation classes in SCSS

## Rules

1. **Define keyframes in SCSS** — `static/css/src/_animations.scss`
2. **Use `animation` utility or custom class** — not inline styles
3. **Respect `prefers-reduced-motion`** — disable animations for users who opt out
4. **GPU-safe properties only** — `transform` and `opacity` in keyframes
5. **Remove animation classes from Alpine.js `x-show` elements** — documented gotcha

## Patterns

### SCSS Keyframe Definitions

```scss
/* static/css/src/_animations.scss */
@keyframes fade-in {
  from { opacity: 0; transform: translateY(0.5rem); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes slide-in-right {
  from { transform: translateX(100%); }
  to { transform: translateX(0); }
}

@keyframes pulse-soft {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

.animate-fade-in {
  animation: fade-in 0.3s ease-out both;
}

.animate-slide-in-right {
  animation: slide-in-right 0.3s ease-out both;
}

.animate-pulse-soft {
  animation: pulse-soft 2s ease-in-out infinite;
}
```

### Usage in Templates

```html
<!-- Fade-in card list -->
<div class="animate-fade-in" style="animation-delay: 0.1s">Card 1</div>
<div class="animate-fade-in" style="animation-delay: 0.2s">Card 2</div>
<div class="animate-fade-in" style="animation-delay: 0.3s">Card 3</div>

<!-- Loading spinner -->
<div class="w-6 h-6 border-2 border-[var(--color-border)]
            border-t-[var(--color-accent)] rounded-full animate-spin"></div>

<!-- Pulsing indicator -->
<span class="inline-block w-2 h-2 rounded-full
             bg-[var(--color-status-success)] animate-pulse-soft"></span>
```

### Staggered Animation with Alpine.js

```html
<div x-data="{ loaded: false }" x-init="setTimeout(() => loaded = true, 100)">
  <template x-for="(item, i) in items" :key="item.id">
    <div :class="loaded ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'"
         class="transition-all duration-300 ease-out"
         :style="'transition-delay: ' + (i * 80) + 'ms'" x-cloak>
      <span x-text="item.name"></span>
    </div>
  </template>
</div>
```

### Reduced Motion Respect

```scss
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `animate-bounce` on `x-show` | Animation overrides display:none | Use Alpine `x-transition` instead |
| Keyframes animating `width`/`height` | Layout thrashing | Use `transform: scale()` |
| No `prefers-reduced-motion` handling | Accessibility issue | Add reduced-motion media query |
| Infinite animations on static content | Distracting, battery drain | Use finite animations or `hover:` trigger |

## Red Flags

- Keyframe animations on layout properties (width, height, margin)
- Missing `prefers-reduced-motion` override
- Animation classes on elements with `x-show` (documented gotcha)
- Excessive use of infinite animations

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `static/css/src/_animations.scss` — keyframe definitions
- `.claude/rules/alpine-patterns.md` — x-show animation conflict
