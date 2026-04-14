---
name: alp-error-boundary
description: "Error boundary patterns for Alpine components. Use when: preventing one component crash from breaking the whole page, graceful degradation, catching runtime errors in Alpine."
---

# Alpine Error Boundary Patterns

## When to Use

- Preventing a single component's JavaScript error from breaking the entire page
- Gracefully degrading when a component fails to initialize
- Catching and logging errors in complex Alpine components

## Patterns

### Try/Catch in init()

```html
<div x-data="{
  data: null,
  error: null,
  init() {
    try {
      const raw = this.$el.dataset.config;
      this.data = JSON.parse(raw);
    } catch (e) {
      this.error = 'Failed to load configuration';
      console.error('Alpine component init error:', e);
    }
  }
}" data-config='{{ config_json }}'>
  <template x-if="error">
    <div class="p-4 rounded bg-red-500/10 border border-red-500/30 text-red-400">
      <span x-text="error"></span>
    </div>
  </template>
  <template x-if="data && !error">
    <div x-text="data.title"></div>
  </template>
</div>
```

### Safe Fetch with Error State

```html
<div x-data="{
  items: [],
  loading: true,
  error: null,
  async init() {
    try {
      const res = await fetch('/api/v1/widgets/');
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      this.items = await res.json();
    } catch (e) {
      this.error = 'Unable to load data. Please try again.';
      console.error('Fetch error:', e);
    } finally {
      this.loading = false;
    }
  }
}">
  <div x-show="loading" x-cloak>{% include "components/_loading.html" %}</div>
  <div x-show="error" x-cloak class="p-4 rounded bg-red-500/10 text-red-400">
    <p x-text="error"></p>
    <button @click="error = null; loading = true; init()" class="mt-2 underline">Retry</button>
  </div>
  <template x-for="item in items" :key="item.id">
    <div x-text="item.name"></div>
  </template>
</div>
```

### Global Error Handler

```html
<script>
document.addEventListener('alpine:init', () => {
  window.addEventListener('error', (event) => {
    if (event.filename?.includes('alpine')) {
      console.error('Alpine runtime error:', event.message);
    }
  });
});
</script>
```

### Safe Method Wrapper

```html
<script>
function safeAction(fn) {
  return async function (...args) {
    try { return await fn.apply(this, args); }
    catch (e) { this.error = e.message; console.error(e); }
  };
}

document.addEventListener('alpine:init', () => {
  Alpine.data('safeWidget', () => ({
    error: null,
    doStuff: safeAction(async function () {
      // risky code here
    })
  }));
});
</script>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| No error handling in `init()` | Bad data crashes entire page | Wrap in try/catch |
| Swallowing errors silently | Bugs hidden, never fixed | Always `console.error` |
| Generic "Something went wrong" | No actionable info for user | Show specific message + retry |

## Red Flags

- Components with `fetch()` but no error/catch handling
- JSON parsing from dataset without try/catch
- No user-visible feedback when a component fails

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
