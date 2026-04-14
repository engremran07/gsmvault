---
name: alp-reduced-motion
description: "Reduced motion: prefers-reduced-motion media query. Use when: respecting user accessibility preferences, disabling animations for vestibular disorders, conditional transition usage."
---

# Alpine Reduced Motion Support

## When to Use

- Respecting `prefers-reduced-motion` OS/browser setting
- Conditionally disabling or simplifying Alpine transitions
- Accessibility compliance (WCAG 2.1 SC 2.3.3)

## Patterns

### Detect Preference in Alpine Store

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('a11y', {
    reducedMotion: window.matchMedia('(prefers-reduced-motion: reduce)').matches,
    init() {
      window.matchMedia('(prefers-reduced-motion: reduce)')
        .addEventListener('change', (e) => {
          this.reducedMotion = e.matches;
        });
    }
  });
});
</script>
```

### Conditional Transitions

```html
<div x-data="{ open: false }">
  <button @click="open = !open">Toggle</button>

  <!-- Full transition when motion is OK -->
  <template x-if="!$store.a11y.reducedMotion">
    <div x-show="open" x-cloak
         x-transition:enter="transition ease-out duration-200"
         x-transition:enter-start="opacity-0 -translate-y-2"
         x-transition:enter-end="opacity-100 translate-y-0"
         x-transition:leave="transition ease-in duration-150"
         x-transition:leave-start="opacity-100"
         x-transition:leave-end="opacity-0"
         class="p-4 bg-[var(--color-surface-alt)] rounded">
      Animated content
    </div>
  </template>

  <!-- Instant show/hide when motion is reduced -->
  <template x-if="$store.a11y.reducedMotion">
    <div x-show="open" x-cloak
         class="p-4 bg-[var(--color-surface-alt)] rounded">
      Animated content
    </div>
  </template>
</div>
```

### Simpler: Opacity-Only Transition

```html
<div x-data="{ open: false }">
  <button @click="open = !open">Toggle Panel</button>
  <div x-show="open" x-cloak
       x-transition:enter="transition ease-out"
       :x-transition:enter-duration="$store.a11y.reducedMotion ? '0ms' : '200ms'"
       x-transition:leave="transition ease-in"
       class="p-4 rounded bg-[var(--color-surface)]">
    Content with optional animation
  </div>
</div>
```

### CSS-Only Approach (Complementary)

```css
/* In static/css/src/_animations.scss */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Stagger Disabled for Reduced Motion

```html
<template x-for="(item, i) in items" :key="item.id">
  <div x-intersect.once="$el.classList.add('opacity-100')"
       class="opacity-0 transition-opacity"
       :style="$store.a11y.reducedMotion ? '' : `transition-delay: ${i * 100}ms`">
    <span x-text="item.name"></span>
  </div>
</template>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Ignoring `prefers-reduced-motion` entirely | Accessibility failure | Check and respect the preference |
| Removing all visual feedback | User can't tell what changed | Keep opacity/instant transitions |
| Hardcoded animation durations | Can't be overridden | Use CSS variables or conditional JS |

## Red Flags

- Scroll-triggered animations with no reduced-motion check
- Staggered animations that can't be disabled
- Auto-playing carousels or slideshows without motion preference check

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
