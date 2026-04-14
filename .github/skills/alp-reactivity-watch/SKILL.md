---
name: alp-reactivity-watch
description: "$watch for reactive side effects. Use when: running callbacks when reactive data changes, syncing state to localStorage, triggering fetch on filter change."
---

# Alpine $watch — Reactive Side Effects

## When to Use

- Running side effects when a specific reactive property changes
- Syncing Alpine state to localStorage on change
- Triggering API calls when filter/search state updates
- Logging or analytics when state transitions occur

## Patterns

### Basic $watch in init()

```html
<div x-data="{
  search: '',
  results: [],
  init() {
    this.$watch('search', (value) => {
      if (value.length >= 3) {
        fetch(`/api/v1/search/?q=${encodeURIComponent(value)}`)
          .then(r => r.json())
          .then(data => this.results = data);
      } else {
        this.results = [];
      }
    });
  }
}">
  <input x-model.debounce.300ms="search" type="text" placeholder="Search..."
         class="w-full px-3 py-2 rounded border border-[var(--color-border)]">
  <template x-for="item in results" :key="item.id">
    <div x-text="item.name" class="p-2"></div>
  </template>
</div>
```

### Persist to localStorage on Change

```html
<div x-data="{
  viewMode: localStorage.getItem('viewMode') || 'grid',
  init() {
    this.$watch('viewMode', (val) => localStorage.setItem('viewMode', val));
  }
}">
  <button @click="viewMode = 'grid'" :class="{ 'bg-[var(--color-accent)]': viewMode === 'grid' }">Grid</button>
  <button @click="viewMode = 'list'" :class="{ 'bg-[var(--color-accent)]': viewMode === 'list' }">List</button>
</div>
```

### Watch with Old Value Comparison

```html
<div x-data="{
  tab: 'overview',
  init() {
    this.$watch('tab', (newVal, oldVal) => {
      console.log(`Tab changed: ${oldVal} → ${newVal}`);
    });
  }
}">
  <button @click="tab = 'overview'">Overview</button>
  <button @click="tab = 'specs'">Specs</button>
  <button @click="tab = 'downloads'">Downloads</button>
</div>
```

### Watch Nested Property

```html
<div x-data="{
  filters: { brand: '', category: '' },
  init() {
    this.$watch('filters', (val) => {
      const params = new URLSearchParams(val).toString();
      htmx.ajax('GET', `/firmwares/fragments/list/?${params}`, '#firmware-list');
    }, { deep: true });
  }
}">
  <select x-model="filters.brand"><option value="">All</option></select>
  <select x-model="filters.category"><option value="">All</option></select>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `$watch` that modifies the watched property | Infinite loop | Guard with `if (new !== old)` or use separate state |
| Heavy synchronous work in watcher | Blocks UI | Use async or debounce |
| Watching deeply nested object without `{ deep: true }` | Changes not detected | Add `{ deep: true }` option |

## Red Flags

- `$watch` callback that sets the same watched property (potential loop)
- Missing debounce on search/filter watchers (fires on every keystroke)
- `$watch` used where `x-effect` would be simpler

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
