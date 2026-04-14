---
name: ads-format-interstitial
description: "Interstitial ads: full-screen, frequency capping. Use when: implementing full-page overlays, between-page transitions, frequency cap per session/user."
---

# Interstitial Ad Format

## When to Use
- Implementing full-screen ad overlays between page navigations
- Configuring frequency capping (max shows per session/day)
- `AdUnit.ad_format = "interstitial"` placements
- Download gate interstitials before firmware download

## Rules
- Interstitials MUST have a visible skip/close button after a delay (5s default)
- Maximum 1 interstitial per user session per page category
- Frequency cap: configurable via `AdsSettings` or `Campaign` settings
- Interstitials blocked on mobile under 300px viewport (Google policy)
- Track show count in session storage or `AdEvent` records

## Patterns

### Interstitial Component
```html
{# templates/ads/fragments/interstitial.html #}
<div x-data="interstitialAd('{{ placement.slot_id }}', { skipDelay: 5 })" x-cloak
     x-show="visible"
     class="fixed inset-0 z-50 flex items-center justify-center bg-black/80">

  <div class="relative bg-[var(--color-bg-primary)] rounded-lg max-w-2xl w-full mx-4 p-6">
    {# Skip button — appears after delay #}
    <button x-show="canSkip"
            x-transition
            @click="dismiss()"
            class="absolute top-3 right-3 px-3 py-1 text-sm
                   bg-[var(--color-bg-tertiary)] rounded hover:bg-[var(--color-bg-hover)]">
      Skip Ad <span x-text="countdown" x-show="countdown > 0"></span>
    </button>

    <div class="ad-content" data-slot="{{ placement.slot_id }}">
      {{ placement.render_code|safe }}
    </div>
  </div>
</div>
```

### Frequency Cap Logic
```python
# apps/ads/services/targeting.py
from apps.ads.models import AdEvent

def check_interstitial_cap(*, user_id: int, daily_limit: int = 3) -> bool:
    """Return True if user can see another interstitial today."""
    today_count = AdEvent.objects.filter(
        user_id=user_id,
        event_type="impression",
        ad_format="interstitial",
        created_at__date=timezone.now().date(),
    ).count()
    return today_count < daily_limit
```

## Anti-Patterns
- No skip button or instant-close — violates ad policies
- Interstitials on every page navigation — drives users away
- Showing interstitials on mobile viewports < 300px wide
- No frequency cap — same user sees interstitial repeatedly

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
