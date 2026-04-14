---
name: alp-store-persistence
description: "Store persistence with localStorage. Use when: persisting user preferences, theme, sidebar state, remembering UI choices across page loads."
---

# Alpine Store Persistence

## When to Use

- Persisting theme preference (`dark`, `light`, `contrast`) across reloads
- Remembering sidebar open/closed state
- Saving user UI preferences without a backend round-trip

## Patterns

### Theme Store with localStorage

```html
<script>
document.addEventListener('alpine:init', () => {
  Alpine.store('theme', {
    current: localStorage.getItem('theme') || 'dark',
    set(value) {
      this.current = value;
      localStorage.setItem('theme', value);
      document.documentElement.setAttribute('data-theme', value);
    }
  });
  document.documentElement.setAttribute('data-theme', Alpine.store('theme').current);
});
</script>
```

### Generic Persisted Store Helper

```html
<script>
function persistedStore(key, defaults) {
  let saved = {};
  try { saved = JSON.parse(localStorage.getItem(key) || '{}'); } catch {}
  const store = { ...defaults, ...saved };
  store._persist = function () {
    const data = {};
    for (const k of Object.keys(defaults)) {
      if (typeof this[k] !== 'function') data[k] = this[k];
    }
    localStorage.setItem(key, JSON.stringify(data));
  };
  return store;
}

document.addEventListener('alpine:init', () => {
  Alpine.store('prefs', persistedStore('userPrefs', {
    sidebarOpen: true,
    compactView: false,
    toggle(key) { this[key] = !this[key]; this._persist(); }
  }));
});
</script>
```

### Reading Persisted Store in a Component

```html
<aside x-data x-show="$store.prefs.sidebarOpen" x-cloak
       x-transition:enter="transition ease-out duration-200"
       x-transition:leave="transition ease-in duration-150">
  <!-- sidebar content -->
</aside>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `localStorage.getItem()` without try/catch | Throws in private browsing / quota exceeded | Always wrap in try/catch |
| Persisting every keystroke | Performance thrash | Debounce or persist on specific actions only |
| Storing sensitive data in localStorage | XSS can read it | Never store tokens/passwords — use httpOnly cookies |
| Relying solely on localStorage for auth state | Stale after logout | Auth state from server, UI prefs from localStorage |

## Red Flags

- Missing fallback when localStorage is unavailable (private mode, disabled)
- Theme flicker on load — `data-theme` must be set synchronously before paint
- Storing user PII or credentials in localStorage

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
