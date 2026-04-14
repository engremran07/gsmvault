---
name: ads-format-vignette
description: "Vignette ads: between page transitions. Use when: implementing between-page ad overlays, page-transition monetization, turbo/HTMX navigation interstitials."
---

# Vignette Ad Format

## When to Use
- Showing ads during page-to-page transitions
- Implementing vignettes triggered by internal link clicks
- Displaying a brief ad overlay before navigating to next page
- Content-heavy sites with frequent page transitions (firmware catalog, forum)

## Rules
- Vignettes differ from interstitials: triggered by navigation, not page load
- Show for a fixed duration (3-5 seconds) then auto-navigate
- Skip button available immediately — user can dismiss and proceed
- Maximum 1 vignette per 5 navigation events (frequency cap)
- NEVER show vignettes on HTMX partial requests — full page only
- Track via `AdEvent(event_type="impression", ad_format="vignette")`

## Patterns

### Vignette on Link Click
```javascript
// static/js/src/ads/vignette.js
function initVignetteAds(options = { frequency: 5, durationMs: 4000 }) {
  let navCount = parseInt(sessionStorage.getItem('nav_count') || '0');

  document.querySelectorAll('a[data-vignette]').forEach(link => {
    link.addEventListener('click', (e) => {
      navCount++;
      sessionStorage.setItem('nav_count', navCount.toString());

      if (navCount % options.frequency !== 0) return;

      e.preventDefault();
      const dest = link.href;
      showVignetteOverlay(dest, options.durationMs);
    });
  });
}

function showVignetteOverlay(destinationUrl, durationMs) {
  const overlay = document.getElementById('vignette-overlay');
  overlay.classList.remove('hidden');
  setTimeout(() => { window.location.href = destinationUrl; }, durationMs);
}
```

### Vignette Overlay Template
```html
{# templates/ads/fragments/vignette.html #}
<div id="vignette-overlay" class="hidden fixed inset-0 z-50 bg-black/90
     flex items-center justify-center" x-cloak>
  <div class="text-center max-w-lg">
    <div class="ad-content mb-4" data-slot="vignette-transition">
      {{ placement.render_code|safe }}
    </div>
    <button onclick="window.location.href = this.dataset.dest"
            class="text-sm text-[var(--color-text-muted)] underline">
      Skip to page →
    </button>
  </div>
</div>
```

## Anti-Patterns
- Vignettes on every single navigation — extreme user friction
- No skip button — traps user in ad overlay
- Triggering vignettes on HTMX/fragment navigations — partial updates break
- Vignette duration > 5 seconds without auto-skip

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
