---
name: template-tags-custom
description: "Custom template tags: simple_tag, inclusion_tag, assignment_tag. Use when: creating reusable template logic, building template tag libraries, rendering sub-templates."
---

# Custom Template Tags

## When to Use
- Rendering reusable UI snippets with `inclusion_tag`
- Computing values for templates with `simple_tag`
- Building template tag libraries for app-specific logic
- Displaying formatted data that views shouldn't compute

## Rules
- Place in `apps/<app>/templatetags/<taglib>.py` — with `__init__.py` in `templatetags/`
- ALWAYS use `template.Library()` for registration
- NEVER do database queries in template tags — pass data from views
- NEVER call external APIs or services — tags are read-only presenters
- Keep tag functions under 15 lines — complex logic goes in views/services
- ALWAYS type-hint parameters and return types
- Load in templates: `{% load taglib %}`

## Patterns

### Simple Tag (Output a Value)
```python
# apps/firmwares/templatetags/firmware_tags.py
from django import template

register = template.Library()


@register.simple_tag
def firmware_type_badge(firmware_type: str) -> str:
    """Return CSS class for firmware type badge."""
    badge_map = {
        "official": "bg-green-500",
        "engineering": "bg-yellow-500",
        "readback": "bg-blue-500",
        "modified": "bg-purple-500",
        "other": "bg-gray-500",
    }
    return badge_map.get(firmware_type, "bg-gray-500")
```

```html
{% load firmware_tags %}
<span class="badge {% firmware_type_badge fw.firmware_type %}">
    {{ fw.get_firmware_type_display }}
</span>
```

### Simple Tag with Context
```python
@register.simple_tag(takes_context=True)
def active_nav(context: dict, url_name: str) -> str:
    """Return 'active' CSS class if current path matches URL name."""
    request = context.get("request")
    if request and request.resolver_match:
        if request.resolver_match.url_name == url_name:
            return "active"
    return ""
```

```html
{% load nav_tags %}
<a href="{% url 'firmwares:list' %}" class="nav-link {% active_nav 'list' %}">
    Firmwares
</a>
```

### Inclusion Tag (Render a Sub-Template)
```python
@register.inclusion_tag("firmwares/fragments/_download_button.html")
def download_button(firmware: "Firmware", user: "User | None" = None) -> dict:
    """Render the download button with appropriate state."""
    return {
        "firmware": firmware,
        "can_download": user is not None and user.is_authenticated,
        "requires_ad": not getattr(user, "is_premium", False),
    }
```

```html
<!-- firmwares/fragments/_download_button.html -->
{% if can_download %}
    <a href="{% url 'firmwares:download' pk=firmware.pk %}"
       class="btn btn-primary">
        {% if requires_ad %}Download (Ad-Gated){% else %}Download{% endif %}
    </a>
{% else %}
    <a href="{% url 'users:login' %}" class="btn btn-secondary">
        Login to Download
    </a>
{% endif %}
```

```html
<!-- Usage in parent template -->
{% load firmware_tags %}
{% download_button firmware user %}
```

### Inclusion Tag with Takes Context
```python
@register.inclusion_tag("components/_user_avatar.html", takes_context=True)
def user_avatar(context: dict, size: str = "md") -> dict:
    """Render user avatar from request context."""
    request = context.get("request")
    user = getattr(request, "user", None)
    return {
        "user": user,
        "size": size,
        "avatar_url": getattr(user, "avatar_url", "") if user else "",
    }
```

### Assignment Tag (Store in Variable)
```python
@register.simple_tag
def get_firmware_count(brand_slug: str) -> int:
    """Get firmware count for a brand (pre-computed, not a DB query)."""
    from django.core.cache import cache
    count = cache.get(f"fw_count:{brand_slug}", 0)
    return count
```

```html
{% load firmware_tags %}
{% get_firmware_count "samsung" as samsung_count %}
<p>Samsung has {{ samsung_count }} firmware files.</p>
```

### Tag Library File Structure
```python
# apps/forum/templatetags/forum_tags.py
from django import template
from django.utils.timesince import timesince

register = template.Library()


@register.filter
def time_ago(value) -> str:  # type: ignore[no-untyped-def]
    """Display time since a datetime as 'X ago'."""
    if value is None:
        return ""
    return f"{timesince(value)} ago"


@register.simple_tag
def forum_stats_badge(topic_count: int, reply_count: int) -> str:
    """Return activity level based on counts."""
    total = topic_count + reply_count
    if total > 1000:
        return "very-active"
    if total > 100:
        return "active"
    return "quiet"
```

## Anti-Patterns
- NEVER do `Model.objects.filter()` inside a template tag
- NEVER call `requests.get()` or any HTTP client in a tag
- NEVER modify model state (`.save()`, `.delete()`) in a tag
- NEVER mark a filter as `is_safe=True` if it includes unsanitized user input
- NEVER put business logic in tags — that belongs in services

## Red Flags
- Database query inside a template tag function
- Template tag function exceeding 15 lines
- Missing `{% load taglib %}` causing `TemplateSyntaxError`
- Tag file without `register = template.Library()`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `apps/*/templatetags/` — existing tag libraries
- `.claude/rules/templatetags-layer.md` — template tag rules
