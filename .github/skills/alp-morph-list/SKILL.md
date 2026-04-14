---
name: alp-morph-list
description: "List morphing for efficient updates. Use when: updating sorted/filtered lists without destroying component state, reordering items, live-updating data tables."
---

# Alpine List Morphing

## When to Use

- Reordering a list without losing expanded/selected state on items
- Filtering a displayed list while keeping component state on remaining items
- Live data updates from polling where item state must persist

## Patterns

### Keyed List for Efficient Morph

```html
<div x-data="{
  items: [],
  sortBy: 'name',
  get sorted() {
    return [...this.items].sort((a, b) => a[this.sortBy].localeCompare(b[this.sortBy]));
  }
}">
  <select x-model="sortBy" class="px-3 py-2 rounded border border-[var(--color-border)]">
    <option value="name">Name</option>
    <option value="date">Date</option>
  </select>

  <template x-for="item in sorted" :key="item.id">
    <div x-data="{ expanded: false }" class="border-b border-[var(--color-border)] p-3">
      <button @click="expanded = !expanded" class="font-medium" x-text="item.name"></button>
      <div x-show="expanded" x-cloak x-transition>
        <p x-text="item.description"></p>
      </div>
    </div>
  </template>
</div>
```

### Filter Without State Loss

```html
<div x-data="{
  items: {{ items_json }},
  search: '',
  get filtered() {
    if (!this.search) return this.items;
    const q = this.search.toLowerCase();
    return this.items.filter(i => i.name.toLowerCase().includes(q));
  }
}">
  <input x-model.debounce.300ms="search" type="text" placeholder="Filter..."
         class="w-full px-3 py-2 mb-4 rounded border border-[var(--color-border)]">

  <template x-for="item in filtered" :key="item.id">
    <div class="p-3 border-b border-[var(--color-border)]">
      <span x-text="item.name"></span>
    </div>
  </template>

  <div x-show="filtered.length === 0" x-cloak>
    {% include "components/_empty_state.html" with message="No items match your search" %}
  </div>
</div>
```

### Live-Updating List with Polling

```html
<div x-data="{
  items: [],
  async refresh() {
    const res = await fetch('/api/v1/events/recent/');
    if (res.ok) this.items = await res.json();
  },
  init() {
    this.refresh();
    setInterval(() => this.refresh(), 15000);
  }
}">
  <template x-for="item in items" :key="item.id">
    <div class="flex justify-between p-2 border-b border-[var(--color-border)]">
      <span x-text="item.message"></span>
      <span x-text="item.time" class="text-[var(--color-text-muted)] text-sm"></span>
    </div>
  </template>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `x-for` without `:key` | Alpine can't track items, re-creates all | Always use `:key="item.id"` |
| Replacing entire array on minor change | Destroys child component state | Use morph or merge strategy |
| Index as key (`:key="i"`) | Reorder causes state mismatch | Use stable unique ID |

## Red Flags

- `:key="index"` on lists that reorder or filter
- Missing `:key` on `x-for` — causes full re-render on every change
- Child components losing `x-data` state after parent list update

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
