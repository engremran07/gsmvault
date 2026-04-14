---
name: template-filters-custom
description: "Custom template filters: register.filter, auto-escaping. Use when: transforming values in templates, formatting display text, creating reusable value filters."
---

# Custom Template Filters

## When to Use
- Transforming a value for display: `{{ value|my_filter }}`
- Formatting dates, numbers, currencies, or file sizes
- Truncating or manipulating text for UI display
- Adding CSS classes or HTML attributes conditionally

## Rules
- Filters MUST be pure functions — same input → same output
- Register with `@register.filter` or `@register.filter(is_safe=True)`
- Only mark `is_safe=True` if output is sanitized HTML — otherwise auto-escaping works
- Handle `None` gracefully — return empty string, not raise
- Filters take 1-2 arguments: `value` and optional `arg`
- Keep filters simple — under 10 lines. Complex logic belongs in views

## Patterns

### Basic Value Filter
```python
# apps/core/templatetags/core_filters.py
from django import template

register = template.Library()


@register.filter
def file_size(bytes_value: int | None) -> str:
    """Format bytes as human-readable file size."""
    if bytes_value is None or bytes_value == 0:
        return "0 B"

    units = ["B", "KB", "MB", "GB", "TB"]
    size = float(bytes_value)
    unit_index = 0

    while size >= 1024 and unit_index < len(units) - 1:
        size /= 1024
        unit_index += 1

    return f"{size:.1f} {units[unit_index]}"
```

```html
{% load core_filters %}
<p>File size: {{ firmware.file_size|file_size }}</p>
<!-- Output: "File size: 245.3 MB" -->
```

### Filter with Argument
```python
@register.filter
def truncate_middle(value: str, length: int = 20) -> str:
    """Truncate a string in the middle with ellipsis."""
    if not value or len(value) <= length:
        return value or ""
    half = (length - 3) // 2
    return f"{value[:half]}...{value[-half:]}"
```

```html
{{ long_filename|truncate_middle:30 }}
<!-- "Samsung_Galaxy_S24_...ware_v12.zip" -->
```

### Status Badge Filter
```python
@register.filter
def status_color(status: str) -> str:
    """Return Tailwind color class for a status value."""
    colors = {
        "active": "text-green-500",
        "pending": "text-yellow-500",
        "rejected": "text-red-500",
        "expired": "text-gray-500",
        "processing": "text-blue-500",
    }
    return colors.get(status, "text-gray-400")
```

```html
{% load core_filters %}
<span class="{{ token.status|status_color }}">{{ token.get_status_display }}</span>
```

### Safe HTML Filter (Use Carefully)
```python
@register.filter(is_safe=True)
def linkify_mentions(text: str) -> str:
    """Convert @username mentions to profile links.

    ONLY safe because we construct the HTML ourselves with
    escaped values — no user content is marked safe.
    """
    import re
    from django.utils.html import escape

    def replace_mention(match: re.Match) -> str:
        username = escape(match.group(1))
        return f'<a href="/users/{username}/" class="mention">@{username}</a>'

    return re.sub(r"@(\w+)", replace_mention, escape(text))
```

### Number Formatting Filters
```python
@register.filter
def compact_number(value: int | None) -> str:
    """Format large numbers compactly: 1234 → 1.2K, 1234567 → 1.2M."""
    if value is None:
        return "0"
    if value >= 1_000_000:
        return f"{value / 1_000_000:.1f}M"
    if value >= 1_000:
        return f"{value / 1_000:.1f}K"
    return str(value)


@register.filter
def percentage(value: float | None, decimals: int = 1) -> str:
    """Format a decimal as percentage: 0.856 → '85.6%'."""
    if value is None:
        return "0%"
    return f"{value * 100:.{decimals}f}%"
```

```html
{% load core_filters %}
<span>{{ firmware.download_count|compact_number }} downloads</span>
<span>{{ completion_rate|percentage }}</span>
```

### Boolean Display Filter
```python
@register.filter
def yes_no_icon(value: bool | None) -> str:
    """Return a checkmark or X for boolean values."""
    if value is True:
        return "✓"
    if value is False:
        return "✗"
    return "—"
```

### Chaining Filters
```html
{% load core_filters %}
<!-- Filters chain left to right -->
{{ firmware.description|truncatewords:20|default:"No description" }}
{{ user.username|truncate_middle:15|default:"Anonymous" }}
```

## Anti-Patterns
- NEVER mark `is_safe=True` if the filter includes unescaped user input
- NEVER do database queries in filters
- NEVER modify objects in filters (`obj.save()`)
- NEVER create filters that return complex objects — return strings
- NEVER use `mark_safe()` on user-supplied content

## Red Flags
- `is_safe=True` on a filter that passes through user text unchanged
- Filter function with `Model.objects` call
- `mark_safe(user_input)` — XSS vulnerability
- Filter returning `None` instead of empty string

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `apps/*/templatetags/` — existing filter implementations
- `.claude/rules/templatetags-layer.md` — template tag rules
- `.claude/rules/xss-prevention.md` — XSS safety
