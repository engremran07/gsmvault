---
name: context-processors-custom
description: "Custom context processors: adding global template variables. Use when: providing site-wide data (settings, theme, navigation) to all templates."
---

# Custom Context Processors

## When to Use
- Providing site-wide configuration to all templates (branding, theme)
- Injecting user consent status for every page
- Adding navigation context (active menu, notification count)
- Making feature flags available in templates
- Exposing `DEBUG` flag for conditional template blocks

## Rules
- Context processors run on EVERY template-rendered request — MUST be lightweight
- ALWAYS cache expensive lookups (database queries, API calls)
- ALWAYS return a `dict` — even if empty: `return {}`
- Use descriptive, namespaced keys: `site_settings`, not `settings`
- NEVER return querysets — evaluate to lists or dicts first
- NEVER return sensitive data (passwords, tokens, API keys)
- NEVER do N+1 queries — aggregate in a single query
- Register in `TEMPLATES[0]["OPTIONS"]["context_processors"]`

## Patterns

### Site Settings (Cached Singleton)
```python
# apps/site_settings/context_processors.py
from django.core.cache import cache
from django.http import HttpRequest


def site_settings(request: HttpRequest) -> dict:
    """Provide SiteSettings to all templates. Cached for 5 min."""
    settings_obj = cache.get("ctx:site_settings")
    if settings_obj is None:
        from .models import SiteSettings
        settings_obj = SiteSettings.get_solo()
        cache.set("ctx:site_settings", settings_obj, timeout=300)
    return {"site_settings": settings_obj}
```

### Theme Context
```python
# apps/site_settings/context_processors.py
def theme_context(request: HttpRequest) -> dict:
    """Provide current theme slug for template rendering."""
    # Theme preference stored in cookie or user profile
    theme = request.COOKIES.get("theme", "dark")
    if theme not in ("dark", "light", "contrast"):
        theme = "dark"
    return {"current_theme": theme}
```

### Consent Status
```python
# apps/consent/context_processors.py
def consent_context(request: HttpRequest) -> dict:
    """Provide user's consent status for conditional rendering."""
    from .utils import get_consent_status

    return {
        "consent_status": get_consent_status(request),
        "consent_required": not request.COOKIES.get("consent_accepted"),
    }
```

### Debug Flag
```python
# apps/core/context_processors.py
from django.conf import settings as django_settings


def debug_context(request: HttpRequest) -> dict:
    """Expose DEBUG flag for development-only template blocks."""
    return {"DEBUG": django_settings.DEBUG}
```

### Feature Flags
```python
# apps/core/context_processors.py
from django.core.cache import cache


def feature_flags(request: HttpRequest) -> dict:
    """Provide feature flags for conditional UI rendering."""
    flags = cache.get("ctx:feature_flags")
    if flags is None:
        from apps.core.utils.feature_flags import is_feature_enabled
        flags = {
            "feature_marketplace": is_feature_enabled("marketplace_enabled"),
            "feature_bounty": is_feature_enabled("bounty_enabled"),
            "feature_forum": is_feature_enabled("forum_enabled"),
            "feature_ads": is_feature_enabled("ads_enabled"),
        }
        cache.set("ctx:feature_flags", flags, timeout=60)
    return flags
```

### User Notification Count
```python
# apps/notifications/context_processors.py
def notifications_context(request: HttpRequest) -> dict:
    """Provide unread notification count for the navbar badge."""
    if not getattr(request.user, "is_authenticated", False):
        return {"unread_notifications": 0}

    from django.core.cache import cache
    cache_key = f"ctx:notif_count:{request.user.pk}"
    count = cache.get(cache_key)
    if count is None:
        from .models import Notification
        count = Notification.objects.filter(
            user=request.user, is_read=False
        ).count()
        cache.set(cache_key, count, timeout=30)
    return {"unread_notifications": count}
```

### Registration in Settings
```python
# app/settings.py
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "OPTIONS": {
            "context_processors": [
                # Django built-in
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
                # Custom — keep sorted
                "apps.consent.context_processors.consent_context",
                "apps.core.context_processors.debug_context",
                "apps.core.context_processors.feature_flags",
                "apps.notifications.context_processors.notifications_context",
                "apps.site_settings.context_processors.site_settings",
                "apps.site_settings.context_processors.theme_context",
            ],
        },
    },
]
```

### Template Usage
```html
<!-- site_settings available everywhere -->
<title>{{ site_settings.site_name }} - {{ page_title }}</title>

<!-- Theme applied to HTML root -->
<html data-theme="{{ current_theme }}">

<!-- Feature flag gating -->
{% if feature_marketplace %}
<a href="{% url 'marketplace:list' %}">Marketplace</a>
{% endif %}

<!-- Notification badge -->
{% if unread_notifications > 0 %}
<span class="badge">{{ unread_notifications }}</span>
{% endif %}
```

## Anti-Patterns
- NEVER execute uncached database queries per request
- NEVER call external APIs from context processors
- NEVER modify `request` state in processors — they are read-only
- NEVER return sensitive data (tokens, keys, passwords)
- NEVER add processors for data only needed on one page — pass from view

## Red Flags
- Context processor without caching doing `Model.objects.filter()`
- Returning a raw queryset instead of evaluated list/dict
- Processor that only applies to one page — should be in the view
- Missing `return {}` branch — can cause `TypeError`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `.claude/rules/context-processors.md` — context processor rules
- `apps/*/context_processors.py` — existing processors
- `app/settings.py` — TEMPLATES configuration
