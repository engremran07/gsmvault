---
name: htmx-history-restore
description: "History restore handling with htmx:historyRestore. Use when: restoring page state on back/forward navigation, re-initializing Alpine.js after history restore, fixing stale content on back button."
---

# HTMX History Restore

## When to Use

- Fixing stale content when user presses back button after HTMX navigation
- Re-initializing Alpine.js or Lucide icons after history restore
- Ensuring page state is correct after forward/back navigation

## Rules

1. HTMX caches page snapshots in `localStorage` for history restore
2. `htmx:historyRestore` fires when a cached page is restored
3. Alpine.js components need re-initialization after restore
4. Lucide icons need `lucide.createIcons()` after restore
5. Set `htmx.config.historyCacheSize` to control cache size (default: 10)

## Patterns

### Re-Initialize After History Restore

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:historyRestore', function() {
  // Re-render Lucide icons (SVG replacement)
  if (typeof lucide !== 'undefined') {
    lucide.createIcons();
  }
});
</script>
```

### Configure History Cache

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('DOMContentLoaded', function() {
  htmx.config.historyCacheSize = 20;      // cache last 20 pages
  htmx.config.historyEnabled = true;       // default
  htmx.config.refreshOnHistoryMiss = true; // full reload if cache miss
});
</script>
```

### Disable History for Specific Elements

```html
{# Don't cache this interaction in history #}
<button hx-post="{% url 'forum:toggle_like' topic.pk %}"
        hx-target="#like-btn"
        hx-push-url="false">
  Like
</button>
```

### Handle History Miss (Cache Expired)

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:historyCacheMiss', function(event) {
  // Cache expired — do a full page load instead of showing stale content
  event.detail.path && (window.location.href = event.detail.path);
});
</script>
```

## Anti-Patterns

```javascript
// WRONG — huge history cache consuming localStorage
htmx.config.historyCacheSize = 1000;  // eats user's localStorage

// WRONG — not re-initializing after restore
// Alpine components broken, Lucide icons missing after back button
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| Icons disappear on back button | Lucide not re-initialized | Call `lucide.createIcons()` on historyRestore |
| Alpine components broken after back | State not re-initialized | Listen for `htmx:historyRestore` |
| Stale data on back navigation | Cache shows old content | Set `refreshOnHistoryMiss = true` |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
