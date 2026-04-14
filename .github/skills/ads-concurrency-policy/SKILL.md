---
name: ads-concurrency-policy
description: "Ad concurrency: max ads per page, priority rules. Use when: limiting simultaneous ads, configuring page-level ad density, priority-based slot allocation."
---

# Ad Concurrency Policy

## When to Use
- Limiting total ads displayed per page
- Enforcing priority when multiple placements compete
- Preventing ad density that hurts Core Web Vitals (CLS, LCP)
- Configuring `AdsSettings.aggressiveness` level

## Rules

### Density Limits by Aggressiveness
| Level | Max Ads/Page | In-Content | Sticky | Interstitial |
|-------|-------------|------------|--------|--------------|
| `low` | 3 | 1 | 0 | 0 |
| `medium` | 5 | 2 | 1 | 0 |
| `high` | 8 | 3 | 1 | 1 |
| `aggressive` | 12 | 5 | 1 | 1 |

- Priority: `PlacementAssignment.priority` — lower number = higher priority
- Locked placements (`is_locked = True`) always render regardless of cap
- Above-fold slots get priority over below-fold

## Patterns

### Page-Level Ad Budget
```python
# apps/ads/services/rotation.py
from apps.ads.models import AdsSettings, AdPlacement

DENSITY_LIMITS = {
    "low": {"total": 3, "in_content": 1, "sticky": 0},
    "medium": {"total": 5, "in_content": 2, "sticky": 1},
    "high": {"total": 8, "in_content": 3, "sticky": 1},
    "aggressive": {"total": 12, "in_content": 5, "sticky": 1},
}

def get_placements_for_page(*, page_slots: list[str]) -> list[AdPlacement]:
    """Return prioritized placements respecting density limits."""
    settings = AdsSettings.get_solo()
    limits = DENSITY_LIMITS.get(settings.aggressiveness, DENSITY_LIMITS["medium"])

    placements = AdPlacement.objects.filter(
        slot_id__in=page_slots, is_enabled=True
    ).order_by("priority")

    selected = []
    in_content_count = 0
    for p in placements:
        if len(selected) >= limits["total"]:
            break
        if "in-content" in p.slot_id:
            if in_content_count >= limits["in_content"]:
                continue
            in_content_count += 1
        selected.append(p)
    return selected
```

### Context Processor for Ad Budget
```python
# apps/ads/context_processors.py
def ads_context(request):
    settings = AdsSettings.get_solo()
    return {
        "ads_enabled": settings.ads_enabled,
        "ads_aggressiveness": settings.aggressiveness,
        "max_ads_per_page": DENSITY_LIMITS.get(settings.aggressiveness, {}).get("total", 5),
    }
```

## Anti-Patterns
- No page-level ad cap — ad floods degrade UX and SEO
- Ignoring CLS when stacking multiple above-fold ads
- Hardcoding density limits instead of using `AdsSettings.aggressiveness`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
