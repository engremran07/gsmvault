---
name: urls-patterns
description: "URL pattern best practices: trailing slashes, path vs re_path, ordering. Use when: designing URL schemes, choosing between path() and re_path(), fixing route conflicts."
---

# URL Pattern Best Practices

## When to Use
- Designing URL scheme for a new app
- Fixing URL ordering conflicts or shadowed routes
- Deciding between `path()` and `re_path()`
- Establishing consistent URL naming conventions

## Rules
- ALWAYS use `path()` — `re_path()` only when regex is genuinely required
- ALWAYS include trailing slashes (`APPEND_SLASH = True` is the Django default)
- URL paths are lowercase with hyphens: `/firmware-downloads/` not `/firmwareDownloads/`
- Every pattern MUST have a `name=` for reverse resolution
- Order specific routes before generic ones to prevent shadowing

## Patterns

### Standard CRUD URLs
```python
app_name = "firmwares"

urlpatterns = [
    # List
    path("", views.firmware_list, name="list"),
    # Create
    path("create/", views.firmware_create, name="create"),
    # Detail — AFTER create to avoid "create" matching <slug>
    path("<int:pk>/", views.firmware_detail, name="detail"),
    path("<int:pk>/edit/", views.firmware_edit, name="edit"),
    path("<int:pk>/delete/", views.firmware_delete, name="delete"),
]
```

### HTMX Fragment Routes
```python
urlpatterns = [
    # Full pages
    path("", views.topic_list, name="list"),
    path("<int:pk>/", views.topic_detail, name="detail"),

    # HTMX fragments — prefixed with fragments/
    path("fragments/search/", views.search_fragment, name="search_fragment"),
    path("fragments/<int:pk>/replies/", views.replies_fragment, name="replies_fragment"),
]
```

### Route Ordering (Specific Before Generic)
```python
urlpatterns = [
    # Static routes FIRST
    path("trending/", views.trending, name="trending"),
    path("latest/", views.latest, name="latest"),

    # Parameterized routes AFTER
    path("<slug:slug>/", views.category_detail, name="category_detail"),
    path("<int:pk>/", views.item_detail, name="item_detail"),
]
```

### path() vs re_path()
```python
from django.urls import path, re_path

urlpatterns = [
    # PREFER path() with converters
    path("firmware/<int:pk>/", views.detail, name="detail"),

    # re_path() ONLY for complex regex needs
    re_path(
        r"^archive/(?P<year>\d{4})/(?P<month>\d{2})/$",
        views.archive,
        name="archive",
    ),
]
```

### API URL Conventions
```python
# API patterns under /api/v1/
app_name = "api"

urlpatterns = [
    path("v1/firmwares/", views.FirmwareListAPI.as_view(), name="firmware_list"),
    path("v1/firmwares/<int:pk>/", views.FirmwareDetailAPI.as_view(), name="firmware_detail"),
    path("v1/health/", views.health_check, name="health"),
]
```

## Anti-Patterns
- NEVER omit trailing slashes — breaks consistency with `APPEND_SLASH`
- NEVER use camelCase or PascalCase in URL paths
- NEVER put generic routes (`<slug:slug>/`) before specific routes (`trending/`)
- NEVER create catch-all patterns that shadow other routes
- NEVER duplicate route names within the same namespace
- NEVER use `re_path()` when `path()` with a converter suffices

## Red Flags
- Route `<slug:slug>/` placed before static routes like `create/`
- `re_path(r"(?P<pk>\d+)")` that could be `path("<int:pk>")`
- URL pattern without `name=` parameter
- Mixed trailing-slash conventions

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `app/urls.py` — root URL configuration
- `.claude/rules/urls-layer.md` — URL layer rules
