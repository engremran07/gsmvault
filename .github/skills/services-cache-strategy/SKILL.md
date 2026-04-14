---
name: services-cache-strategy
description: "Caching strategies: per-view, per-object, DistributedCacheManager. Use when: adding caching to views, caching querysets, cache invalidation, using DistributedCacheManager."
---

# Cache Strategy Patterns

## When to Use
- Frequently accessed data that changes infrequently (site settings, category lists)
- Expensive queries that can tolerate staleness (analytics, leaderboards)
- Per-object caching for detail pages
- Cache invalidation on model save/delete

## Rules
- Use `DistributedCacheManager` from `apps.core.cache` for multi-site cache
- Cache keys MUST be namespaced: `"app:model:pk"` format
- Set explicit TTLs — never cache indefinitely (max 24h for most data)
- Invalidate cache in the same transaction as the data change
- Never cache user-specific data in shared cache without user-scoped keys
- Use `cache.get_or_set()` for simple cases

## Patterns

### Per-Object Caching in Services
```python
from django.core.cache import cache
from .models import Firmware

FIRMWARE_CACHE_TTL = 60 * 15  # 15 minutes

def get_firmware_cached(*, pk: int) -> Firmware:
    """Get firmware with cache layer."""
    cache_key = f"firmwares:detail:{pk}"
    firmware = cache.get(cache_key)
    if firmware is None:
        firmware = (
            Firmware.objects
            .select_related("brand", "model")
            .get(pk=pk, is_active=True)
        )
        cache.set(cache_key, firmware, FIRMWARE_CACHE_TTL)
    return firmware

def invalidate_firmware_cache(*, pk: int) -> None:
    cache.delete(f"firmwares:detail:{pk}")
```

### DistributedCacheManager Usage
```python
from apps.core.cache import DistributedCacheManager

dcm = DistributedCacheManager(namespace="firmwares")

def get_popular_firmwares() -> list:
    return dcm.get_or_set(
        key="popular",
        default=lambda: list(
            Firmware.objects.filter(is_active=True)
            .order_by("-download_count")[:20]
            .values("pk", "name", "download_count")
        ),
        ttl=60 * 30,  # 30 minutes
    )
```

### Cache Invalidation via Signal
```python
# apps/firmwares/signals.py
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.core.cache import cache
from .models import Firmware

@receiver(post_save, sender=Firmware)
@receiver(post_delete, sender=Firmware)
def invalidate_firmware_cache(sender, instance, **kwargs):
    cache.delete(f"firmwares:detail:{instance.pk}")
    cache.delete("firmwares:popular")
```

### View-Level Caching
```python
from django.views.decorators.cache import cache_page

@cache_page(60 * 5)  # 5 minutes
def firmware_list(request):
    """Cache entire view response for anonymous users."""
    firmwares = Firmware.objects.filter(is_active=True)
    return render(request, "firmwares/list.html", {"firmwares": firmwares})
```

### Template Fragment Caching
```html
{% load cache %}
{% cache 900 sidebar_categories %}
  <div class="sidebar">
    {% for cat in categories %}
      <a href="{{ cat.get_absolute_url }}">{{ cat.name }}</a>
    {% endfor %}
  </div>
{% endcache %}
```

## Anti-Patterns
- Caching without TTL — stale data forever
- Cache key without namespace — collisions across apps
- Caching user-specific data in shared keys — data leakage
- Invalidating cache outside the transaction — stale data window
- Caching mutable Django model instances — can cause subtle bugs

## Red Flags
- Same expensive query called 5+ times per request without caching
- `cache.set()` without `timeout` parameter
- Cache key like `"data"` without namespace or specificity

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
