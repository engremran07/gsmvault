---
name: ads-slot-positions
description: "Ad slot positioning: header, sidebar, in-content, footer, etc. Use when: deciding where to place ads, configuring viewport zones, mapping slots to page sections."
---

# Ad Slot Positions

## When to Use
- Deciding which page sections get ad slots
- Mapping `AdPlacement.slot_id` to template locations
- Configuring viewport zones from `ScanDiscovery.zone`
- Avoiding CLS (Cumulative Layout Shift) from ad injection

## Rules

### Standard Slot Positions
| Zone | Slot ID Pattern | Location | CLS Risk |
|------|----------------|----------|----------|
| Header | `{page}-header-banner` | Below nav, above content | Low |
| Sidebar Top | `{page}-sidebar-top` | First sidebar widget | Low |
| Sidebar Sticky | `{page}-sidebar-sticky` | Sticky sidebar position | Medium |
| Above Content | `{page}-above-content` | Before main content | Low |
| In-Content | `{page}-in-content-{n}` | Between paragraphs | High |
| Below Content | `{page}-below-content` | After main content | Low |
| Footer | `{page}-footer-banner` | Above footer | Low |
| Interstitial | `{page}-interstitial` | Full-screen overlay | N/A |

### Naming Convention
```text
{app}-{page}-{zone}[-{variant}]
Examples:
  blog-post-sidebar-top
  firmwares-detail-above-content
  forum-topic-in-content-1
```

## Patterns

### Reserving Space to Prevent CLS
```html
{# templates/ads/fragments/placement.html #}
{% if show_ad and placement %}
<div class="ad-slot"
     id="ad-{{ placement.slot_id }}"
     style="min-height: {{ placement.min_height|default:'250' }}px;"
     data-slot="{{ placement.slot_id }}">
  {# Ad content injected here #}
</div>
{% endif %}
```

### In-Content Injection After N Paragraphs
```python
# apps/ads/templatetags/ads_tags.py
@register.simple_tag
def inject_ad_after_paragraph(content: str, slot_id: str, after_para: int = 3) -> str:
    """Insert ad placeholder after the Nth paragraph."""
    paragraphs = content.split("</p>")
    if len(paragraphs) > after_para:
        ad_html = f'<div class="ad-slot" data-slot="{slot_id}"></div>'
        paragraphs.insert(after_para, ad_html)
    return "</p>".join(paragraphs)
```

## Anti-Patterns
- Placing ads above the fold without reserving height — causes CLS
- More than 3 in-content ads on a single page — degrades UX
- Using the same `slot_id` across different pages — causes tracking confusion

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
