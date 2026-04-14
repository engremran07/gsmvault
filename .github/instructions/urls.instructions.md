---
applyTo: 'apps/*/urls.py, app/urls.py'
---

# URL Routing Conventions

## App Namespace

Every app MUST declare its own namespace:

```python
from django.urls import path
from . import views

app_name = "firmwares"

urlpatterns = [
    path("", views.firmware_list, name="list"),
    path("<int:pk>/", views.firmware_detail, name="detail"),
    path("<int:pk>/download/", views.firmware_download, name="download"),
    path("create/", views.firmware_create, name="create"),
]
```

## URL Name Convention

Use `action-object` pattern for URL names:

| URL Name | Pattern | View |
|----------|---------|------|
| `list` | `""` | List view |
| `detail` | `<int:pk>/` | Detail view |
| `create` | `create/` | Create form |
| `update` | `<int:pk>/update/` | Update form |
| `delete` | `<int:pk>/delete/` | Delete confirmation |
| `search` | `search/` | Search view |

## Path Converters

Use `path()` exclusively — never `re_path()` unless absolutely necessary:

```python
# CORRECT
path("<int:pk>/", views.detail, name="detail"),
path("<slug:slug>/", views.category_detail, name="category-detail"),
path("<uuid:token>/", views.verify_email, name="verify-email"),

# WRONG — avoid re_path
re_path(r"^(?P<pk>\d+)/$", views.detail, name="detail"),
```

## Trailing Slashes

All paths MUST have trailing slashes:

```python
# CORRECT
path("firmware/list/", views.list, name="list"),

# WRONG
path("firmware/list", views.list, name="list"),
```

## Include Pattern

In `app/urls.py`, include app URLs with namespace:

```python
from django.urls import include, path

urlpatterns = [
    path("firmwares/", include("apps.firmwares.urls")),
    path("devices/", include("apps.devices.urls")),
    path("forum/", include("apps.forum.urls")),
    path("api/v1/", include("apps.api.urls")),
]
```

## API URL Prefix

All API endpoints live under `/api/v1/`:

```python
# apps/api/urls.py
urlpatterns = [
    path("firmwares/", include("apps.firmwares.api_urls")),
    path("devices/", include("apps.devices.api_urls")),
]
```

## HTMX Fragment URLs

HTMX endpoints that return fragments share the same URL namespace:

```python
urlpatterns = [
    path("", views.firmware_list, name="list"),  # Full page or fragment via HX-Request
    path("search/", views.firmware_search, name="search"),  # Fragment-only
]
```

## Reverse URLs

In templates: `{% url 'firmwares:detail' pk=fw.pk %}`
In Python: `reverse("firmwares:detail", kwargs={"pk": fw.pk})`
In models: Use `reverse_lazy()` for class attributes.
