---
name: ads-placement-manual
description: "Manual placement configuration in templates. Use when: adding ad slots to templates, configuring AdPlacement records, wiring placements to ad units."
---

# Manual Ad Placement

## When to Use
- Adding ad slots to Django templates manually
- Creating `AdPlacement` records for known positions
- Binding ad units to placements via `PlacementAssignment`
- Controlling which creatives appear in which slots

## Rules
- Each `AdPlacement` has a unique `slot_id` used in templates
- `PlacementAssignment` binds creatives/units to placements with weight and priority
- Locked assignments (`is_locked = True`) are never rotated out
- Use `{% include "ads/fragments/placement.html" %}` — never inline ad code
- Check `AdsSettings.ads_enabled` before rendering any placement

## Patterns

### Creating a Placement
```python
# apps/ads/services.py
from apps.ads.models import AdPlacement

def create_placement(
    *, name: str, slot_id: str, description: str = ""
) -> AdPlacement:
    return AdPlacement.objects.create(
        name=name,
        slot_id=slot_id,
        description=description,
        is_enabled=True,
    )
```

### Template Integration
```html
{# templates/blog/post_detail.html #}
{% load ads_tags %}

<article>
  <h1>{{ post.title }}</h1>

  {# Above content ad #}
  {% render_ad_slot "blog-post-above-content" %}

  <div class="prose">{{ post.content }}</div>

  {# Below content ad #}
  {% render_ad_slot "blog-post-below-content" %}
</article>

<aside>
  {% render_ad_slot "blog-sidebar-top" %}
</aside>
```

### Template Tag Implementation
```python
# apps/ads/templatetags/ads_tags.py
from django import template
from apps.ads.models import AdsSettings, AdPlacement

register = template.Library()

@register.inclusion_tag("ads/fragments/placement.html", takes_context=True)
def render_ad_slot(context, slot_id: str):
    settings = AdsSettings.get_solo()
    if not settings.ads_enabled:
        return {"show_ad": False}
    placement = AdPlacement.objects.filter(
        slot_id=slot_id, is_enabled=True
    ).first()
    return {"show_ad": bool(placement), "placement": placement}
```

## Anti-Patterns
- Inlining ad HTML directly in templates instead of using `{% render_ad_slot %}`
- Creating placements without unique `slot_id` — causes rendering conflicts
- Skipping the `AdsSettings.ads_enabled` check in template tags

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
