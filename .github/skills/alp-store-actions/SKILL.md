---
name: alp-store-actions
description: "Store actions and methods. Use when: mutating global store state, defining store methods for add/remove/toggle, async store operations with fetch."
---

# Alpine Store Actions

## When to Use

- Defining methods that mutate global store state (add, remove, toggle, set)
- Performing async operations (fetch) that update store data
- Encapsulating business logic in store methods rather than inline templates

## Patterns

### Basic CRUD Actions

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('bookmarks', {
    items: [],
    add(item) {
      if (!this.items.find(b => b.id === item.id)) {
        this.items.push(item);
      }
    },
    remove(id) {
      this.items = this.items.filter(b => b.id !== id);
    },
    toggle(item) {
      this.has(item.id) ? this.remove(item.id) : this.add(item);
    },
    has(id) {
      return this.items.some(b => b.id === id);
    }
  });
});
</script>
```

### Async Action with Fetch

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('notifications', {
    items: [],
    loading: false,
    async fetch() {
      this.loading = true;
      try {
        const res = await fetch('/api/v1/notifications/', {
          headers: { 'X-CSRFToken': document.querySelector('[name=csrfmiddlewaretoken]')?.value || '' }
        });
        if (res.ok) this.items = await res.json();
      } finally {
        this.loading = false;
      }
    },
    async markRead(id) {
      await fetch(`/api/v1/notifications/${id}/read/`, { method: 'POST',
        headers: { 'X-CSRFToken': document.querySelector('[name=csrfmiddlewaretoken]')?.value || '' }
      });
      const item = this.items.find(n => n.id === id);
      if (item) item.read = true;
    }
  });
});
</script>
```

### Using Actions in Templates

```html
<div x-data>
  <button @click="$store.bookmarks.toggle({ id: {{ fw.pk }}, name: '{{ fw.name|escapejs }}' })">
    <template x-if="$store.bookmarks.has({{ fw.pk }})"><i data-lucide="bookmark-check"></i></template>
    <template x-if="!$store.bookmarks.has({{ fw.pk }})"><i data-lucide="bookmark"></i></template>
  </button>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Mutation logic in templates | Hard to debug, duplicated | Move to store methods |
| `fetch()` without CSRF header | 403 on POST/PUT/DELETE | Include `X-CSRFToken` header |
| No error handling in async actions | Silent failures | Add try/catch, set error state |
| Direct `this.items.splice()` in template | Reactivity issues | Use store method with reassignment |

## Red Flags

- Inline mutation logic duplicated across multiple templates
- Async actions without loading/error state management
- CSRF token missing on mutating fetch calls

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
