---
name: alp-transitions-stagger
description: "Staggered animations with x-transition. Use when: animating list items one by one, sequential card reveal, cascading fade-in effects for grid items."
---

# Alpine Staggered Transitions

## When to Use

- List items appear one after another with a delay between each
- Grid cards cascade in on page load or filter change
- Notification stack items slide in sequentially

## Patterns

### Staggered List Items with CSS Transition Delay

```html
<div x-data="{ show: false }" x-init="$nextTick(() => show = true)">
  <template x-for="(item, i) in ['Alpha', 'Beta', 'Gamma', 'Delta']" :key="i">
    <div x-show="show" x-cloak
         x-transition:enter="transition ease-out duration-300"
         x-transition:enter-start="opacity-0 translate-y-4"
         x-transition:enter-end="opacity-100 translate-y-0"
         :style="`transition-delay: ${i * 75}ms`"
         class="p-3 border-b border-[var(--color-border)]">
      <span x-text="item"></span>
    </div>
  </template>
</div>
```

### Staggered Grid Cards

```html
<div x-data="{ visible: false, items: [] }"
     x-init="fetch('/api/v1/firmwares/recent/').then(r => r.json()).then(data => { items = data; $nextTick(() => visible = true); })">
  <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
    <template x-for="(item, i) in items" :key="item.id">
      <div x-show="visible" x-cloak
           x-transition:enter="transition ease-out duration-300"
           x-transition:enter-start="opacity-0 scale-95"
           x-transition:enter-end="opacity-100 scale-100"
           :style="`transition-delay: ${i * 50}ms`"
           class="rounded-lg p-4 bg-[var(--color-surface)] shadow">
        <h3 x-text="item.name"></h3>
      </div>
    </template>
  </div>
</div>
```

### Manual Stagger with setTimeout

For more control, stagger by toggling visibility per item:

```html
<div x-data="{
  items: ['A', 'B', 'C', 'D'],
  visibleCount: 0,
  init() {
    const reveal = () => {
      if (this.visibleCount < this.items.length) {
        this.visibleCount++;
        setTimeout(reveal, 80);
      }
    };
    reveal();
  }
}">
  <template x-for="(item, i) in items" :key="i">
    <div x-show="i < visibleCount" x-cloak x-transition x-text="item"
         class="p-2">
    </div>
  </template>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Same delay for all items | No stagger effect | Use index-based delay: `i * 75` |
| Very long total stagger (>1s for full list) | Feels slow | Cap at ~50-80ms per item |
| Using CSS `animation-delay` with `x-show` | `display:none` conflict | Use `x-transition` + inline `transition-delay` style |

## Red Flags

- Stagger delay total exceeds 1 second for the visible set
- Missing `x-cloak` — all items flash then re-animate
- `animate-*` classes on staggered `x-show` items

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
