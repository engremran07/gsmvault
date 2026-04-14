---
name: ads-format-sticky
description: "Sticky ad format: fixed position, close button. Use when: implementing anchor/sticky ads, adding dismiss functionality, viewport-pinned ad slots."
---

# Sticky Ad Format

## When to Use
- Implementing bottom-anchored or sidebar-sticky ads
- Adding user-dismissible close buttons
- Configuring sticky ad duration and re-show intervals
- `AdUnit.ad_format = "anchor"` placements

## Rules
- Sticky ads MUST have a visible close button — no exception
- Bottom-anchor ads hidden on mobile if Google policies require it
- Close state stored in `localStorage` with a cooldown period
- Sticky ads must not cover navigation or primary content
- Maximum 1 sticky ad visible at any time per page

## Patterns

### Sticky Ad Component
```html
{# templates/ads/fragments/sticky_ad.html #}
<div x-data="{ dismissed: false }" x-cloak
     x-show="!dismissed"
     x-init="dismissed = localStorage.getItem('sticky_ad_dismissed_{{ placement.slot_id }}') === 'true'"
     class="fixed bottom-0 left-0 right-0 z-40 bg-[var(--color-bg-primary)]
            border-t border-[var(--color-border)] p-2 shadow-lg
            hidden lg:flex items-center justify-center">

  {# Close button — always visible #}
  <button @click="dismissed = true; localStorage.setItem('sticky_ad_dismissed_{{ placement.slot_id }}', 'true')"
          class="absolute top-1 right-2 text-[var(--color-text-muted)] hover:text-[var(--color-text-primary)]"
          aria-label="Close ad">
    <i data-lucide="x" class="w-4 h-4"></i>
  </button>

  <div class="ad-content max-w-[728px]" data-slot="{{ placement.slot_id }}">
    {{ placement.render_code|safe }}
  </div>
</div>
```

### Cooldown Re-show Logic
```javascript
// static/js/src/ads/sticky.js
function shouldShowStickyAd(slotId, cooldownMinutes = 30) {
  const key = `sticky_ad_dismissed_${slotId}`;
  const dismissedAt = localStorage.getItem(key);
  if (!dismissedAt) return true;
  const elapsed = (Date.now() - parseInt(dismissedAt)) / 60000;
  return elapsed >= cooldownMinutes;
}
```

## Anti-Patterns
- Sticky ads without close buttons — violates ad policies
- Multiple simultaneous sticky ads — overwhelming UX
- Sticky ads covering the mobile nav hamburger menu
- No cooldown after dismiss — ad reappears immediately on next page

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
