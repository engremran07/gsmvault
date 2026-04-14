---
name: alp-store-init
description: "Alpine.store initialization patterns. Use when: creating global state stores, registering Alpine stores before Alpine.start(), initializing shared reactive state."
---

# Alpine Store Initialization

## When to Use

- Creating global state accessible across multiple components
- Registering shared data (theme, sidebar, auth status, notifications)
- Setting up stores that must be available before any component renders

## Patterns

### Basic Store Registration

Register stores **before** `Alpine.start()` in `base.html` or a dedicated `<script>`:

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('sidebar', {
    open: false,
    toggle() { this.open = !this.open; }
  });
});
</script>
```

### Store with Initial Data from Django

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('user', {
    isAuthenticated: {{ user.is_authenticated|yesno:"true,false" }},
    username: '{{ user.username|escapejs }}',
  });
});
</script>
```

### Accessing Stores in Components

```html
<div x-data>
  <button @click="$store.sidebar.toggle()">
    <span x-show="!$store.sidebar.open" x-cloak>Open</span>
    <span x-show="$store.sidebar.open" x-cloak>Close</span>
  </button>
</div>
```

### Multiple Stores — Separation of Concerns

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('theme', { current: 'dark' });
  Alpine.store('notifications', { count: 0, items: [] });
  Alpine.store('modal', { active: null, data: {} });
});
</script>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Registering store after `Alpine.start()` | Store unavailable during init | Use `alpine:init` event |
| Storing ephemeral UI state in global store | Pollutes global namespace | Use `x-data` for local state |
| Calling `Alpine.start()` twice | Duplicate bindings, errors | Remove extra calls — `base.html` calls it once |
| Inline `<script>` outside `alpine:init` | Race condition with Alpine load | Always wrap in `alpine:init` listener |

## Red Flags

- `Alpine.store(...)` called outside `alpine:init` or after `Alpine.start()`
- Component-local state (dropdown open, form field) in a global store
- Missing `x-cloak` on elements reading from `$store`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
