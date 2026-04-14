---
name: ads-network-killswitch
description: "Network killswitch: per-network enable/disable. Use when: disabling problematic networks, emergency ad shutoff, toggling networks without deletion."
---

# Network Killswitch

## When to Use
- Emergency disabling a network serving malvertising
- Toggling networks on/off for A/B testing
- Implementing master ads killswitch via `AdsSettings.ads_enabled`
- Per-network enable/disable without data loss

## Rules
- `AdsSettings.ads_enabled` is the master switch — if False, ALL ads stop
- `AdsSettings.ad_networks_enabled` controls whether network waterfall runs
- `AdNetwork.is_enabled` is the per-network toggle
- Never delete a network to disable it — use `is_enabled = False`
- Killswitch changes take effect immediately — no cache delay

## Patterns

### Master Killswitch Check
```python
# apps/ads/services.py
from apps.ads.models import AdsSettings

def is_ads_active() -> bool:
    """Check if ads system is globally enabled."""
    settings = AdsSettings.get_solo()
    return settings.ads_enabled and settings.ad_networks_enabled
```

### Per-Network Toggle
```python
def toggle_network(*, network_id: int, enabled: bool) -> AdNetwork:
    network = AdNetwork.objects.get(pk=network_id)
    network.is_enabled = enabled
    network.save(update_fields=["is_enabled", "updated_at"])
    return network
```

### Emergency Shutdown Service
```python
def emergency_shutdown_all_networks(*, reason: str) -> int:
    """Disable all networks immediately. Returns count of disabled networks."""
    count = AdNetwork.objects.filter(is_enabled=True).update(
        is_enabled=False,
        sync_status=f"Emergency shutdown: {reason}",
    )
    settings = AdsSettings.get_solo()
    settings.ads_enabled = False
    settings.save(update_fields=["ads_enabled"])
    return count
```

### Template Guard
```html
{% load ads_tags %}
{% if ads_enabled %}
  {% include "ads/fragments/placement.html" with placement=sidebar_ad %}
{% endif %}
```

## Anti-Patterns
- Deleting `AdNetwork` records instead of disabling — loses historical data
- Caching killswitch state for long TTLs — must be near-real-time
- Checking only `AdNetwork.is_enabled` without checking master `AdsSettings.ads_enabled`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
