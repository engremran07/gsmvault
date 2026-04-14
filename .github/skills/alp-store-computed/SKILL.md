---
name: alp-store-computed
description: "Computed properties in Alpine stores. Use when: deriving values from store state, creating getters, calculating totals or filtered counts from store data."
---

# Alpine Store Computed Properties

## When to Use

- Deriving display values from store state (e.g., badge counts, formatted strings)
- Creating getter-like properties that recalculate when dependencies change
- Filtering or aggregating store data for UI display

## Patterns

### Getter-Style Computed Property

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('cart', {
    items: [],
    get total() {
      return this.items.reduce((sum, item) => sum + item.price * item.qty, 0);
    },
    get count() {
      return this.items.reduce((sum, item) => sum + item.qty, 0);
    },
    get isEmpty() {
      return this.items.length === 0;
    }
  });
});
</script>
```

### Using Computed in Templates

```html
<div x-data>
  <span x-text="$store.cart.count" x-cloak></span>
  <span x-show="!$store.cart.isEmpty" x-cloak
        x-text="'$' + $store.cart.total.toFixed(2)">
  </span>
</div>
```

### Notification Store with Computed Filters

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('notifications', {
    items: [],
    get unread() { return this.items.filter(n => !n.read); },
    get unreadCount() { return this.unread.length; },
    get hasUnread() { return this.unreadCount > 0; },
    markRead(id) {
      const item = this.items.find(n => n.id === id);
      if (item) item.read = true;
    }
  });
});
</script>

<span x-data x-show="$store.notifications.hasUnread" x-cloak
      class="bg-red-500 text-white rounded-full px-2 text-xs"
      x-text="$store.notifications.unreadCount">
</span>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Heavy computation inside getter | Runs on every access | Cache result, recalculate on mutation |
| Side effects inside getters | Unpredictable re-runs | Move side effects to actions |
| Deeply nested reactive objects in getters | Proxy overhead | Keep store data flat |

## Red Flags

- Getter that modifies state (should be read-only)
- Complex nested object traversal in a getter accessed on every render
- Missing `x-cloak` on elements displaying computed values

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
