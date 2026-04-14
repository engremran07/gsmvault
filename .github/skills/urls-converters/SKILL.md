---
name: urls-converters
description: "Path converters: int, str, slug, uuid, custom converters. Use when: defining URL parameters, creating custom path converters, choosing between int/slug/uuid."
---

# URL Path Converters

## When to Use
- Defining URL parameters with type constraints
- Choosing between `<int:pk>`, `<slug:slug>`, `<uuid:token>`
- Creating custom converters for domain-specific URL segments
- Migrating from `re_path()` to `path()` with converters

## Rules
- ALWAYS use `path()` with typed converters — avoid `re_path()` unless regex is genuinely needed
- Use `<int:pk>` for database primary keys
- Use `<slug:slug>` for SEO-friendly URLs
- Use `<uuid:token>` for security-sensitive identifiers (download tokens, API keys)
- NEVER expose sequential IDs for sensitive resources — use UUIDs

## Patterns

### Built-in Converters
```python
from django.urls import path

urlpatterns = [
    # int — matches positive integers
    path("firmware/<int:pk>/", views.detail, name="detail"),

    # str — matches any non-empty string (excluding /)
    path("brand/<str:name>/", views.brand, name="brand"),

    # slug — matches slug strings (letters, numbers, hyphens, underscores)
    path("category/<slug:slug>/", views.category, name="category"),

    # uuid — matches UUID strings
    path("download/<uuid:token>/", views.download, name="download"),

    # path — matches any string including /
    path("docs/<path:doc_path>/", views.doc, name="doc"),
]
```

### Custom Converter
```python
# app/converters.py
class FirmwareTypeConverter:
    """Matches firmware type slugs: official, engineering, readback, modified."""

    regex = r"official|engineering|readback|modified|other"

    def to_python(self, value: str) -> str:
        return value

    def to_url(self, value: str) -> str:
        return value

# app/urls.py
from django.urls import register_converter
from .converters import FirmwareTypeConverter

register_converter(FirmwareTypeConverter, "fwtype")

urlpatterns = [
    path("firmware/<fwtype:firmware_type>/", views.by_type, name="by_type"),
]
```

### Choosing the Right Converter

| Resource Type | Converter | Example URL | Rationale |
|--------------|-----------|-------------|-----------|
| Database record | `<int:pk>` | `/firmware/42/` | Fast lookup, simple |
| SEO page | `<slug:slug>` | `/blog/my-post/` | Human-readable, crawlable |
| Download token | `<uuid:token>` | `/dl/a1b2c3.../` | Unpredictable, non-enumerable |
| Category tree | `<path:path>` | `/docs/api/v1/auth/` | Nested hierarchy |

## Anti-Patterns
- NEVER use `<str:pk>` for database IDs — use `<int:pk>` for type safety
- NEVER use `<int:pk>` for download tokens — use `<uuid:token>` (prevents enumeration)
- NEVER use `re_path()` when a built-in or custom converter works
- NEVER create converters with overly broad regex that match unintended paths

## Red Flags
- Sequential integer IDs exposed for sensitive resources
- `re_path(r"(?P<pk>\d+)")` that could be `path("<int:pk>")`
- Missing type constraint allowing string injection into integer lookups

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `app/urls.py` — root URL configuration
- Django docs: URL dispatcher > Path converters
