---
name: alp-intersect-lazy
description: "Lazy loading with x-intersect. Use when: deferring image/content loading until visible, reducing initial page load, loading heavy components on scroll."
---

# Alpine Lazy Loading with x-intersect

## When to Use

- Lazy-loading images below the fold
- Deferring heavy component initialization until scrolled into view
- Loading content from API only when the section becomes visible

## Patterns

### Lazy Load Image

Requires `@alpinejs/intersect` plugin:

```html
<div x-data="{ loaded: false }" x-intersect.once="loaded = true">
  <img x-show="loaded" x-cloak
       :src="loaded ? '{{ firmware.image.url }}' : ''"
       alt="{{ firmware.name }}"
       class="w-full h-48 object-cover rounded">
  <div x-show="!loaded" class="w-full h-48 bg-[var(--color-surface-alt)] rounded animate-pulse"></div>
</div>
```

### Lazy Load API Content

```html
<div x-data="{ items: [], loaded: false }"
     x-intersect.once="
       loaded = true;
       fetch('/api/v1/firmwares/popular/')
         .then(r => r.json())
         .then(data => items = data)
     ">
  <div x-show="!loaded" class="h-32 bg-[var(--color-surface-alt)] rounded animate-pulse"></div>
  <template x-if="loaded">
    <div>
      <template x-for="item in items" :key="item.id">
        <div x-text="item.name" class="p-2 border-b border-[var(--color-border)]"></div>
      </template>
    </div>
  </template>
</div>
```

### Lazy Load with Threshold

```html
<div x-data="{ visible: false }"
     x-intersect:enter.margin.200px="visible = true">
  <!-- Loads when within 200px of viewport -->
  <template x-if="visible">
    <iframe src="https://www.youtube.com/embed/..." class="w-full aspect-video rounded"></iframe>
  </template>
  <div x-show="!visible" class="w-full aspect-video bg-[var(--color-surface-alt)] rounded flex items-center justify-center">
    <span class="text-[var(--color-text-muted)]">Video loading...</span>
  </div>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Missing `.once` modifier | Callback fires on every scroll event | Add `.once` for one-time load |
| No placeholder/skeleton | Layout shift when content appears | Show placeholder until loaded |
| Lazy loading above-the-fold content | Delays visible content needlessly | Only lazy-load below fold |

## Red Flags

- `x-intersect` without `.once` for content that only needs to load once
- Content layout shift — missing placeholder with matching dimensions
- `x-intersect` plugin not included in CDN fallback chain

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
