---
name: services-feature-toggle
description: "Feature toggle implementation: settings-based, per-user flags. Use when: gating features behind flags, gradual rollout, A/B testing setup, enabling features per tier."
---

# Feature Toggle Patterns

## When to Use
- Gradual rollout of new features
- Enabling/disabling features without deployment
- Per-user or per-tier feature access
- Kill switches for risky features

## Rules
- Feature flags stored in `SiteSettings` (singleton) or dedicated `FeatureFlag` model
- Use `apps.core.utils.feature_flags` for flag checking
- Flags must have sensible defaults — features work when the flag model is missing
- Admin-toggleable via admin panel (no code deploy needed)
- Log flag evaluations for debugging (at DEBUG level only)

## Patterns

### Settings-Based Feature Flags
```python
# apps/site_settings/models.py — on the SiteSettings singleton
class SiteSettings(SingletonModel):
    # Feature flags
    enable_forum = models.BooleanField(default=True)
    enable_marketplace = models.BooleanField(default=False)
    enable_bounty_system = models.BooleanField(default=False)
    enable_ai_analytics = models.BooleanField(default=True)
    maintenance_mode = models.BooleanField(default=False)
```

### Checking Flags in Services
```python
from apps.site_settings.models import SiteSettings

def is_feature_enabled(feature_name: str) -> bool:
    """Check if a feature is enabled in site settings."""
    try:
        settings = SiteSettings.get_solo()
        return getattr(settings, f"enable_{feature_name}", False)
    except Exception:
        return False  # Fail closed

# Usage:
def create_bounty(*, user_id: int, **kwargs):
    if not is_feature_enabled("bounty_system"):
        raise FeatureDisabledError("Bounty system is currently disabled")
    # ... proceed
```

### Per-User Feature Flags
```python
class UserFeatureFlag(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    feature = models.CharField(max_length=100, db_index=True)
    enabled = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "feature")

def user_has_feature(*, user_id: int, feature: str) -> bool:
    """Check if a specific user has a feature enabled."""
    # Check user-level override first
    user_flag = UserFeatureFlag.objects.filter(
        user_id=user_id, feature=feature
    ).first()
    if user_flag is not None:
        return user_flag.enabled
    # Fall back to global flag
    return is_feature_enabled(feature)
```

### Percentage Rollout
```python
import hashlib

def is_feature_rolled_out(*, user_id: int, feature: str, percentage: int) -> bool:
    """Deterministic percentage-based rollout."""
    hash_input = f"{feature}:{user_id}".encode()
    hash_value = int(hashlib.md5(hash_input).hexdigest(), 16) % 100  # noqa: S324
    return hash_value < percentage
```

### View Guard with Feature Toggle
```python
from functools import wraps
from django.http import Http404

def require_feature(feature_name: str):
    """Decorator to gate views behind a feature flag."""
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            if not is_feature_enabled(feature_name):
                raise Http404("Feature not available")
            return view_func(request, *args, **kwargs)
        return wrapper
    return decorator

# Usage:
@require_feature("marketplace")
def marketplace_list(request):
    ...
```

### Template Check
```html
{% if features.enable_forum %}
  <a href="{% url 'forum:index' %}">Community Forum</a>
{% endif %}
```

## Anti-Patterns
- Hardcoded feature flags in code — deploy to toggle
- Feature flags without defaults — crashes when DB is empty
- Leaving old feature flags forever — clean up after full rollout
- Feature flags that require code changes to modify

## Red Flags
- `if True:` or `if False:` as feature toggle — use proper flags
- Feature flag checked but no admin UI to toggle it
- Dozens of stale feature flags that are all `True` — clean up

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
