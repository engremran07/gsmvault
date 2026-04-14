---
name: alp-localStorage-safe
description: "Safe localStorage access with fallbacks. Use when: reading/writing localStorage in Alpine, handling private browsing mode, quota exceeded errors, SSR-safe patterns."
---

# Safe localStorage Access in Alpine

## When to Use

- Persisting user preferences (theme, sidebar state, view mode)
- Handling private browsing where localStorage may throw
- Storage quota exceeded errors
- Environments where `localStorage` may be undefined

## Patterns

### Safe Read/Write Helper

```html
<script>
function safeStorage(key, fallback) {
  return {
    get() {
      try { return JSON.parse(localStorage.getItem(key)) ?? fallback; }
      catch { return fallback; }
    },
    set(value) {
      try { localStorage.setItem(key, JSON.stringify(value)); }
      catch (e) { console.warn('localStorage write failed:', e.message); }
    },
    remove() {
      try { localStorage.removeItem(key); }
      catch { /* ignore */ }
    }
  };
}
</script>
```

### Theme Store with Safe Storage

```html
<script>
document.addEventListener('alpine:init', () => {
  const storage = safeStorage('theme', 'dark');

  Alpine.store('theme', {
    current: storage.get(),
    set(val) {
      this.current = val;
      storage.set(val);
      document.documentElement.setAttribute('data-theme', val);
    }
  });
});
</script>
```

### Component with Persisted State

```html
<div x-data="{
  sidebarOpen: safeStorage('sidebarOpen', true).get(),
  toggle() {
    this.sidebarOpen = !this.sidebarOpen;
    safeStorage('sidebarOpen', true).set(this.sidebarOpen);
  }
}">
  <button @click="toggle()">
    <span x-text="sidebarOpen ? 'Collapse' : 'Expand'"></span>
  </button>
  <aside x-show="sidebarOpen" x-cloak x-transition
         class="w-64 bg-[var(--color-surface-alt)]">
    Sidebar content
  </aside>
</div>
```

### Feature Detection Guard

```html
<script>
const hasLocalStorage = (() => {
  try {
    const key = '__ls_test__';
    localStorage.setItem(key, '1');
    localStorage.removeItem(key);
    return true;
  } catch {
    return false;
  }
})();

document.addEventListener('alpine:init', () => {
  Alpine.store('prefs', {
    _cache: {},
    get(key, fallback) {
      if (key in this._cache) return this._cache[key];
      if (!hasLocalStorage) return fallback;
      try {
        const val = localStorage.getItem(key);
        return val !== null ? JSON.parse(val) : fallback;
      } catch { return fallback; }
    },
    set(key, value) {
      this._cache[key] = value;
      if (!hasLocalStorage) return;
      try { localStorage.setItem(key, JSON.stringify(value)); }
      catch { /* quota exceeded — memory-only */ }
    }
  });
});
</script>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Bare `localStorage.getItem()` without try/catch | Throws in private browsing mode or when disabled | Wrap in try/catch |
| Storing large data blobs | Quota exceeded (5MB limit) | Store minimal keys; use IndexedDB for large data |
| `JSON.parse(null)` | Returns `null`, may break downstream | Use `?? fallback` |

## Red Flags

- Direct `localStorage` calls without error handling
- No fallback when `localStorage` is unavailable
- Storing sensitive data (tokens, passwords) in localStorage

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
