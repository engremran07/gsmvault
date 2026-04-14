---
name: ads-format-native
description: "Native ad format: blended with content. Use when: implementing in-feed ads, sponsored content cards, ads that match content styling."
---

# Native Ad Format

## When to Use
- Displaying ads styled to match surrounding content
- In-feed sponsored items (firmware listings, blog feed, forum topics)
- `AdUnit.ad_format = "native"` or `"in_feed"` placements
- Networks with `supports_native = True` (Taboola, Outbrain, MGID)

## Rules
- Native ads MUST be clearly labeled "Sponsored" or "Ad" — FTC requirement
- Style with the same CSS tokens as surrounding content cards
- Never disguise ads as actual content — deceptive patterns are forbidden
- Use `_card.html` component as base and add a sponsor badge
- Track impressions via `AdEvent` with `ad_format="native"`

## Patterns

### Native Ad Card
```html
{# templates/ads/fragments/native_ad.html #}
{% load ads_tags %}
<div class="card bg-[var(--color-bg-secondary)] rounded-lg p-4 border border-[var(--color-border)]"
     data-slot="{{ placement.slot_id }}"
     data-ad-format="native">

  {# Sponsor label — REQUIRED #}
  <div class="flex items-center justify-between mb-2">
    <span class="text-xs uppercase tracking-wide text-[var(--color-text-muted)]
                 bg-[var(--color-bg-tertiary)] px-2 py-0.5 rounded">
      Sponsored
    </span>
    <span class="text-xs text-[var(--color-text-muted)]">{{ creative.advertiser }}</span>
  </div>

  {% if creative.image_url %}
    <img src="{{ creative.image_url }}" alt="{{ creative.title }}"
         class="w-full rounded-md mb-3 object-cover h-40" loading="lazy">
  {% endif %}

  <h4 class="font-semibold text-[var(--color-text-primary)] mb-1">{{ creative.title }}</h4>
  <p class="text-sm text-[var(--color-text-secondary)] mb-3">{{ creative.body|truncatewords:25 }}</p>

  <a href="{{ creative.cta_url }}" rel="sponsored noopener" target="_blank"
     class="text-sm font-medium text-[var(--color-accent-text)]">
    {{ creative.cta_text|default:"Learn More" }}
  </a>
</div>
```

### In-Feed Injection
```python
# apps/ads/services/rotation.py
def inject_native_ads(*, items: list, slot_prefix: str, every_n: int = 5) -> list:
    """Insert native ad placeholders every N items in a feed."""
    result = []
    ad_index = 0
    for i, item in enumerate(items):
        result.append(item)
        if (i + 1) % every_n == 0:
            result.append({"_is_ad": True, "slot_id": f"{slot_prefix}-{ad_index}"})
            ad_index += 1
    return result
```

## Anti-Patterns
- Native ads without "Sponsored" / "Ad" label — FTC violation
- Styling ads to be visually indistinguishable from content
- Using `rel="dofollow"` on ad links — must be `rel="sponsored"`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
