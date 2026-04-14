---
name: ads-network-integration
description: "Ad network integration: 18 network types, provider config. Use when: adding new ad networks, configuring AdNetwork models, waterfall priority setup."
---

# Ad Network Integration

## When to Use
- Adding a new ad network provider (AdSense, Media.net, Ezoic, etc.)
- Configuring `AdNetwork` model instances with credentials
- Setting up waterfall priority across multiple networks
- Injecting network-specific `<head>` or `<body>` scripts

## Rules
- All ad networks live in `apps.ads.models.AdNetwork` — 18 `NETWORK_TYPES`
- Credentials stored in model fields (`api_key`, `api_secret`, `publisher_id`) — never in code
- Priority field controls waterfall order: higher number = tried first
- Each network declares capabilities: `supports_display`, `supports_native`, `supports_video`, `supports_rewarded`
- Network scripts injected via `header_script` / `body_script` — sanitized with `sanitize_ad_code()`

## Patterns

### Creating a Network Provider
```python
# apps/ads/services.py
from apps.ads.models import AdNetwork

def register_network(
    *, name: str, network_type: str, publisher_id: str, priority: int = 10
) -> AdNetwork:
    return AdNetwork.objects.create(
        name=name,
        network_type=network_type,
        publisher_id=publisher_id,
        priority=priority,
        is_enabled=False,  # Always start disabled
    )
```

### Waterfall Selection
```python
def get_active_networks(*, ad_format: str = "display") -> QuerySet[AdNetwork]:
    """Return enabled networks supporting the requested format, ordered by priority."""
    filters = {"is_enabled": True, "is_deleted": False}
    if ad_format == "video":
        filters["supports_video"] = True
    elif ad_format == "native":
        filters["supports_native"] = True
    elif ad_format == "rewarded":
        filters["supports_rewarded"] = True
    return AdNetwork.objects.filter(**filters).order_by("-priority")
```

### Injecting Network Scripts in Templates
```html
{# templates/base/base.html — inside <head> #}
{% for network in active_networks %}
  {% if network.header_script %}
    {{ network.header_script|safe }}
  {% endif %}
{% endfor %}
```

## Anti-Patterns
- Hardcoding network IDs or publisher keys in templates or settings
- Enabling a network before verifying credentials with `last_sync_at`
- Ignoring `revenue_share_percent` when comparing network performance
- Importing ad network config in non-ads apps — use EventBus

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
