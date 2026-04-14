---
name: alp-component-lifecycle
description: "Component lifecycle: init(), destroy(). Use when: setting up timers/intervals on mount, cleaning up event listeners, running initialization logic when component appears."
---

# Alpine Component Lifecycle

## When to Use

- Running setup logic when a component initializes (fetch data, start timers)
- Cleaning up resources when a component is removed from DOM
- Registering/deregistering global event listeners tied to a component's lifetime

## Patterns

### init() — Runs on Component Mount

```html
<div x-data="{
  count: 0,
  init() {
    console.log('Component mounted');
    this.count = parseInt(this.$el.dataset.initial || '0');
  }
}" data-initial="{{ initial_count }}">
  <span x-text="count"></span>
</div>
```

### destroy() — Cleanup on Removal

```html
<div x-data="{
  intervalId: null,
  elapsed: 0,
  init() {
    this.intervalId = setInterval(() => { this.elapsed++; }, 1000);
  },
  destroy() {
    if (this.intervalId) clearInterval(this.intervalId);
  }
}">
  <span x-text="elapsed + 's'"></span>
</div>
```

### Async Init with Fetch

```html
<div x-data="{
  items: [],
  loading: true,
  async init() {
    try {
      const res = await fetch('/api/v1/devices/recent/');
      if (res.ok) this.items = await res.json();
    } finally {
      this.loading = false;
    }
  }
}">
  <div x-show="loading" x-cloak>Loading...</div>
  <template x-for="item in items" :key="item.id">
    <div x-text="item.name"></div>
  </template>
</div>
```

### Global Listener with Cleanup

```html
<div x-data="{
  handler: null,
  init() {
    this.handler = (e) => { /* handle resize */ };
    window.addEventListener('resize', this.handler);
  },
  destroy() {
    window.removeEventListener('resize', this.handler);
  }
}">
  <!-- component content -->
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `setInterval` without `destroy()` cleanup | Memory leak, ghost timers | Always clear in `destroy()` |
| `addEventListener` without `removeEventListener` | Leaked listeners accumulate | Store handler ref, remove in `destroy()` |
| Heavy sync work in `init()` | Blocks rendering | Use `async init()` or `$nextTick` |
| Using `x-init` AND `init()` method together | Double initialization | Pick one — `init()` method preferred |

## Red Flags

- `setInterval` or `setTimeout` without corresponding cleanup in `destroy()`
- Global event listeners added in `init()` without removal
- Fetch calls in `init()` without loading/error states

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
