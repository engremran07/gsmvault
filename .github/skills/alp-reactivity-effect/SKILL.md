---
name: alp-reactivity-effect
description: "Alpine.effect for computed dependencies. Use when: auto-tracking reactive dependencies, running side effects that depend on multiple reactive values, replacing manual $watch chains."
---

# Alpine.effect — Auto-Tracked Reactive Effects

## When to Use

- Side effects that depend on multiple reactive values (auto-tracked)
- Simpler alternative to multiple `$watch` calls
- Computed DOM updates that depend on several state properties

## Patterns

### Basic x-effect for Class Binding

```html
<div x-data="{ count: 0, limit: 10 }">
  <span x-text="count"></span>
  <button @click="count++">+</button>
  <p x-effect="$el.classList.toggle('text-red-500', count >= limit)">
    <!-- Auto-updates when count or limit changes -->
  </p>
</div>
```

### x-effect for Side Effects

```html
<div x-data="{ query: '', category: '' }">
  <input x-model.debounce.300ms="query" placeholder="Search...">
  <select x-model="category">
    <option value="">All</option>
    <option value="firmware">Firmware</option>
  </select>

  <template x-effect="
    if (query.length >= 2 || category) {
      const params = new URLSearchParams({ q: query, cat: category });
      htmx.ajax('GET', '/search/fragments/results/?' + params, '#results');
    }
  "></template>
  <div id="results"></div>
</div>
```

### Alpine.effect in Store Init

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('theme', {
    current: localStorage.getItem('theme') || 'dark',
    set(val) { this.current = val; }
  });

  Alpine.effect(() => {
    const theme = Alpine.store('theme').current;
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  });
});
</script>
```

### Effect for Title Update

```html
<div x-data="{ page: 'Dashboard' }">
  <template x-effect="document.title = page + ' — GSMFWs Admin'"></template>
  <button @click="page = 'Users'">Users</button>
  <button @click="page = 'Firmwares'">Firmwares</button>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Mutating tracked state inside effect | Infinite re-run loop | Effects should be read-only side effects |
| Heavy DOM manipulation in effect | Blocks reactivity cycle | Batch updates, use `$nextTick` |
| Using `x-effect` for simple bindings | Overkill | Use `x-bind` or `x-text` instead |

## Red Flags

- `x-effect` that writes back to its own tracked dependencies
- Effect running expensive operations without debouncing
- Using `x-effect` where `x-bind:class` or `x-text` suffices

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
