---
name: settings-feature-flags
description: "Feature flag patterns: boolean settings, runtime toggles. Use when: gating features behind toggles, adding A/B testing, progressive rollout, conditional functionality."
---

# Feature Flags

## When to Use
- Gating new features behind toggles for progressive rollout
- Enabling/disabling features per environment (dev vs production)
- Runtime feature control without deployments (via database)
- A/B testing or canary releases

## Rules
- Static flags: use `settings.py` environment variables for deploy-time toggles
- Dynamic flags: use `SiteSettings` singleton (database) for runtime toggles
- ALWAYS provide a safe default (usually `False` — feature off)
- NEVER use feature flags for permanent code — remove after full rollout
- Check flags at the view/service layer, not in models or templates

## Patterns

### Static Flags (Environment Variables)
```python
# app/settings.py
import os

FEATURE_FLAGS = {
    "ENABLE_AI_FEATURES": os.environ.get("ENABLE_AI_FEATURES", "false").lower() == "true",
    "ENABLE_MARKETPLACE": os.environ.get("ENABLE_MARKETPLACE", "false").lower() == "true",
    "ENABLE_BOUNTY_SYSTEM": os.environ.get("ENABLE_BOUNTY_SYSTEM", "false").lower() == "true",
}
```

### Checking Static Flags
```python
# In views
from django.conf import settings

def marketplace_list(request: HttpRequest) -> HttpResponse:
    if not settings.FEATURE_FLAGS.get("ENABLE_MARKETPLACE", False):
        raise Http404("Marketplace is not available.")
    # ... normal view logic
```

### Dynamic Flags (Database via SiteSettings)
```python
# apps/site_settings/models.py
class SiteSettings(SingletonModel):
    # Feature toggles — changeable at runtime via admin
    ads_enabled = models.BooleanField(default=True)
    affiliate_enabled = models.BooleanField(default=False)
    ai_features_enabled = models.BooleanField(default=False)
    forum_enabled = models.BooleanField(default=True)
    maintenance_mode = models.BooleanField(default=False)
```

### Checking Dynamic Flags in Services
```python
# apps/ads/services/ad_service.py
from django.core.cache import cache


def is_ads_enabled() -> bool:
    """Check if ads system is globally enabled. Cached for 60s."""
    enabled = cache.get("feature:ads_enabled")
    if enabled is None:
        from apps.site_settings.models import SiteSettings
        settings = SiteSettings.get_solo()
        enabled = settings.ads_enabled
        cache.set("feature:ads_enabled", enabled, timeout=60)
    return enabled
```

### Feature Flag Utility (apps.core)
```python
# apps/core/utils/feature_flags.py
from django.core.cache import cache


def is_feature_enabled(flag_name: str, default: bool = False) -> bool:
    """Check a feature flag — first tries DB (cached), then settings.

    Args:
        flag_name: The flag identifier (e.g., "ads_enabled")
        default: Fallback if flag not found anywhere
    """
    # 1. Check cached DB setting
    cache_key = f"feature:{flag_name}"
    cached = cache.get(cache_key)
    if cached is not None:
        return cached

    # 2. Check SiteSettings model
    from apps.site_settings.models import SiteSettings
    settings_obj = SiteSettings.get_solo()
    value = getattr(settings_obj, flag_name, None)
    if value is not None:
        cache.set(cache_key, value, timeout=60)
        return value

    # 3. Check Django settings FEATURE_FLAGS dict
    from django.conf import settings
    flags = getattr(settings, "FEATURE_FLAGS", {})
    return flags.get(flag_name, default)
```

### Gating in Templates
```python
# Context processor provides flags
def feature_flags(request: HttpRequest) -> dict[str, bool]:
    from apps.core.utils.feature_flags import is_feature_enabled
    return {
        "feature_marketplace": is_feature_enabled("marketplace_enabled"),
        "feature_bounty": is_feature_enabled("bounty_enabled"),
    }
```

```html
<!-- Template usage -->
{% if feature_marketplace %}
    <a href="{% url 'marketplace:list' %}">Marketplace</a>
{% endif %}
```

## Anti-Patterns
- NEVER check feature flags in models — check in views/services
- NEVER leave dead feature flags in code after full rollout
- NEVER use feature flags as permanent configuration — that's what settings are for
- NEVER query the database for a flag on every request without caching

## Red Flags
- Uncached database query for flag checked on every request
- Feature flag with no plan for removal after rollout
- Flag checked in `models.py` instead of view/service layer
- Missing default value — crashes when flag doesn't exist

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `apps/site_settings/models.py` — SiteSettings with toggle fields
- `apps/core/utils/feature_flags.py` — feature flag utilities
