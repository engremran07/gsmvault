---
name: alp-intersect-animation
description: "Scroll-triggered animations. Use when: animating elements as they scroll into view, reveal-on-scroll effects, section entrance animations on landing pages."
---

# Alpine Scroll-Triggered Animations

## When to Use

- Revealing sections as user scrolls down the page
- Entrance animations for cards, stats, images on scroll
- Landing page progressive content reveal

## Patterns

### Fade-In on Scroll

```html
<div x-data="{ visible: false }" x-intersect.once="visible = true"
     x-show="visible" x-cloak
     x-transition:enter="transition ease-out duration-700"
     x-transition:enter-start="opacity-0 translate-y-8"
     x-transition:enter-end="opacity-100 translate-y-0"
     class="p-6 rounded-lg bg-[var(--color-surface)]">
  <h2>Feature Section</h2>
  <p>This content animates in when scrolled into view.</p>
</div>
```

### Staggered Cards on Scroll

```html
<div x-data="{ visible: false }" x-intersect.once="visible = true"
     class="grid grid-cols-1 md:grid-cols-3 gap-6">
  <template x-for="(stat, i) in [
    { label: 'Downloads', value: '1.2M' },
    { label: 'Devices', value: '5,400+' },
    { label: 'Users', value: '89K' }
  ]" :key="i">
    <div x-show="visible" x-cloak
         x-transition:enter="transition ease-out duration-500"
         x-transition:enter-start="opacity-0 scale-90"
         x-transition:enter-end="opacity-100 scale-100"
         :style="`transition-delay: ${i * 100}ms`"
         class="p-6 rounded-lg bg-[var(--color-surface)] text-center shadow">
      <div class="text-3xl font-bold text-[var(--color-accent)]" x-text="stat.value"></div>
      <div class="text-[var(--color-text-muted)]" x-text="stat.label"></div>
    </div>
  </template>
</div>
```

### Slide-In from Side

```html
<div x-data="{ visible: false }" x-intersect.once="visible = true">
  <div x-show="visible" x-cloak
       x-transition:enter="transition ease-out duration-600"
       x-transition:enter-start="opacity-0 -translate-x-12"
       x-transition:enter-end="opacity-100 translate-x-0">
    <!-- Slides in from the left -->
    <p>Content slides in from the left on scroll.</p>
  </div>
</div>
```

### Respecting Reduced Motion

```html
<div x-data="{
  visible: false,
  prefersReducedMotion: window.matchMedia('(prefers-reduced-motion: reduce)').matches
}" x-intersect.once="visible = true"
   x-show="visible" x-cloak
   :class="prefersReducedMotion ? '' : 'transition ease-out duration-500'"
   :style="!visible && !prefersReducedMotion ? 'opacity:0; transform:translateY(1rem)' : ''">
  Accessible animated content
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| CSS `animate-*` on intersect-triggered elements | Conflicts with `x-show` | Use `x-transition` exclusively |
| Missing `.once` | Animation replays on every scroll | Add `.once` for single reveal |
| Animation on critical content | Content hidden until scroll | Only animate decorative/enhancement elements |
| No reduced-motion fallback | Motion-sensitive users impacted | Check `prefers-reduced-motion` |

## Red Flags

- Scroll animations without `.once` — content flickers on scroll
- Important content gated behind scroll animation (SEO/accessibility issue)
- No `prefers-reduced-motion` consideration

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
