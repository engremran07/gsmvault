---
name: ads-slot-responsive
description: "Responsive ad slots: mobile/tablet/desktop sizing. Use when: configuring ad unit dimensions per breakpoint, hiding ads on mobile, responsive ad containers."
---

# Responsive Ad Slots

## When to Use
- Configuring ad sizes per device breakpoint
- Hiding sidebar ads on mobile (sidebar collapses)
- Using responsive ad units (`width=0, height=0` in `AdUnit`)
- Preventing ads from breaking mobile layouts

## Rules
- `AdUnit.width = 0` and `AdUnit.height = 0` means responsive/fluid
- `AdUnit.size_label` = `"responsive"` or `"fluid"` for auto-sizing
- Sidebar ads hidden on mobile — sidebar collapses below `lg` breakpoint
- Sticky ads disabled on mobile — limited viewport space
- In-content ads use full-width on mobile, constrained on desktop

## Patterns

### Responsive Ad Container
```html
{# templates/ads/fragments/placement.html #}
{% if show_ad and placement %}
<div class="ad-slot w-full overflow-hidden"
     data-slot="{{ placement.slot_id }}"
     {% if placement.ad_unit and placement.ad_unit.width %}
       style="max-width: {{ placement.ad_unit.width }}px;"
     {% endif %}>

  {# Hide on mobile for sidebar placements #}
  {% if "sidebar" in placement.slot_id %}
    <div class="hidden lg:block">
      {{ placement.render_code|safe }}
    </div>
  {% else %}
    {{ placement.render_code|safe }}
  {% endif %}
</div>
{% endif %}
```

### Size Selection by Breakpoint
```python
# apps/ads/services/rotation.py
def select_ad_size(*, placement: AdPlacement, viewport_width: int) -> tuple[int, int]:
    """Select appropriate ad size based on viewport."""
    if viewport_width < 768:  # Mobile
        return (320, 100)  # Mobile banner
    elif viewport_width < 1024:  # Tablet
        return (468, 60)  # Standard banner
    else:  # Desktop
        return (728, 90)  # Leaderboard
```

### Tailwind Responsive Classes
```html
{# Full-width on mobile, constrained on desktop #}
<div class="ad-slot w-full md:max-w-[728px] mx-auto">
  {% render_ad_slot "blog-post-above-content" %}
</div>

{# Hidden on small screens, visible on large #}
<div class="hidden lg:block">
  {% render_ad_slot "sidebar-sticky" %}
</div>
```

## Anti-Patterns
- Fixed pixel ad sizes that overflow on mobile viewports
- Showing interstitial/sticky ads on mobile — violates Google policies
- Not testing ad rendering at all breakpoints before going live

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
