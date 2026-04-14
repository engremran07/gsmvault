---
name: tw-placeholder-shimmer
description: "Shimmer animation for loading states. Use when: creating shimmer/shine effect on skeleton loaders, building premium loading experiences."
---

# Shimmer Animation

## When to Use

- Adding a polished shimmer/shine effect to skeleton loaders
- Creating a gradient sweep animation over placeholders
- Building premium perceived-performance experiences

## Rules

1. **Define shimmer keyframes in SCSS** — `_animations.scss`
2. **Use `overflow-hidden` on shimmer container** — prevent shine leaking
3. **Shimmer is a gradient pseudo-element** — sweeps across the skeleton
4. **Respect `prefers-reduced-motion`** — disable shimmer for motion-sensitive users
5. **Theme-aware shimmer colours** — subtle highlight on theme background

## Patterns

### Shimmer Keyframes in SCSS

```scss
/* static/css/src/_animations.scss */
@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

.shimmer {
  position: relative;
  overflow: hidden;

  &::after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: linear-gradient(
      90deg,
      transparent 0%,
      rgba(255, 255, 255, 0.08) 50%,
      transparent 100%
    );
    animation: shimmer 1.5s ease-in-out infinite;
  }
}

/* Theme-aware shimmer highlight */
[data-theme="light"] .shimmer::after {
  background: linear-gradient(
    90deg,
    transparent 0%,
    rgba(0, 0, 0, 0.04) 50%,
    transparent 100%
  );
}

[data-theme="contrast"] .shimmer::after {
  background: linear-gradient(
    90deg,
    transparent 0%,
    rgba(255, 255, 255, 0.12) 50%,
    transparent 100%
  );
}

@media (prefers-reduced-motion: reduce) {
  .shimmer::after {
    animation: none;
  }
}
```

### Shimmer Card Skeleton

```html
<div class="rounded-lg bg-[var(--color-bg-secondary)] p-4">
  <!-- Image placeholder with shimmer -->
  <div class="shimmer aspect-[4/3] w-full rounded-md
              bg-[var(--color-border)]"></div>

  <!-- Title with shimmer -->
  <div class="shimmer mt-4 h-5 w-3/4 rounded
              bg-[var(--color-border)]"></div>

  <!-- Text lines with shimmer -->
  <div class="mt-2 space-y-2">
    <div class="shimmer h-3 w-full rounded bg-[var(--color-border)]"></div>
    <div class="shimmer h-3 w-5/6 rounded bg-[var(--color-border)]"></div>
  </div>
</div>
```

### Pure Tailwind Shimmer (no SCSS)

```html
<div class="relative overflow-hidden rounded-lg
            bg-[var(--color-bg-secondary)] p-4">
  <div class="h-5 w-2/3 rounded bg-[var(--color-border)]"></div>
  <div class="mt-2 h-3 w-full rounded bg-[var(--color-border)]"></div>
  <div class="mt-2 h-3 w-4/5 rounded bg-[var(--color-border)]"></div>

  <!-- Shimmer overlay -->
  <div class="absolute inset-0 -translate-x-full
              bg-gradient-to-r from-transparent
              via-white/5 to-transparent
              animate-[shimmer_1.5s_ease-in-out_infinite]"></div>
</div>
```

### Shimmer List Items

```html
<ul class="divide-y divide-[var(--color-border)]">
  {% for _ in "12345" %}
  <li class="flex items-center gap-4 py-4">
    <div class="shimmer w-10 h-10 rounded-full bg-[var(--color-border)]"></div>
    <div class="flex-1">
      <div class="shimmer h-4 w-1/3 rounded bg-[var(--color-border)]"></div>
      <div class="shimmer mt-1 h-3 w-2/3 rounded bg-[var(--color-border)]"></div>
    </div>
    <div class="shimmer h-6 w-16 rounded bg-[var(--color-border)]"></div>
  </li>
  {% endfor %}
</ul>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Missing `overflow-hidden` | Shimmer leaks outside rounded corners | Add `overflow-hidden` |
| White shimmer in dark theme | Too bright, distracting | Use `rgba(255,255,255,0.08)` |
| No `prefers-reduced-motion` handling | Accessibility issue | Disable animation for motion-sensitive |
| Shimmer on real content | Confusing, covers actual text | Only on skeleton placeholders |

## Red Flags

- Shimmer without `overflow: hidden` on rounded containers
- Hard-coded shimmer colours that don't adapt to theme
- Missing reduced-motion handling
- Shimmer animation on actual loaded content

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `static/css/src/_animations.scss` — shimmer keyframes
- `templates/components/_loading.html` — loading component
