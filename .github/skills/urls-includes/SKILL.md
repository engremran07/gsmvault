---
name: urls-includes
description: "URL include patterns with namespace prefixes. Use when: organizing URL routing, including app URLs, structuring API routes, adding new apps to routing."
---

# URL Includes

## When to Use
- Adding a new app's URLs to the root URL configuration
- Structuring API endpoint routing under `/api/v1/`
- Organizing admin panel URL imports
- Splitting large URL files into sub-modules

## Rules
- ALWAYS use `include()` with `namespace=` matching the app's `app_name`
- URL prefixes use lowercase with hyphens: `firmware-downloads/`
- API routes nest under `/api/v1/` prefix
- Admin panel URLs go through `apps/admin/urls.py`
- Group includes logically: public pages, API, admin, auth

## Patterns

### Standard App Include
```python
# app/urls.py
from django.urls import include, path

urlpatterns = [
    # Public pages
    path("", include("apps.pages.urls", namespace="pages")),
    path("blog/", include("apps.blog.urls", namespace="blog")),
    path("firmwares/", include("apps.firmwares.urls", namespace="firmwares")),
    path("forum/", include("apps.forum.urls", namespace="forum")),
    path("shop/", include("apps.shop.urls", namespace="shop")),

    # Auth
    path("accounts/", include("apps.users.urls", namespace="users")),

    # API
    path("api/v1/", include("apps.api.urls", namespace="api")),

    # Admin
    path("admin-panel/", include("apps.admin.urls", namespace="custom_admin")),
]
```

### API Sub-Includes
```python
# apps/api/urls.py
from django.urls import include, path

app_name = "api"

urlpatterns = [
    path("firmwares/", include("apps.firmwares.api_urls")),
    path("devices/", include("apps.devices.api_urls")),
    path("blog/", include("apps.blog.api_urls")),
    path("health/", views.health_check, name="health"),
]
```

### Admin URL Organization
```python
# apps/admin/urls.py
from . import (
    views_auth,
    views_content,
    views_distribution,
    views_extended,
    views_infrastructure,
    views_security,
    views_settings,
    views_users,
)

app_name = "custom_admin"

urlpatterns = [
    path("", views.dashboard, name="dashboard"),
    # Each view module contributes its own patterns
    path("auth/", include([
        path("login/", views_auth.login_view, name="login"),
    ])),
    path("content/", include([
        path("blog/", views_content.blog_list, name="blog_list"),
    ])),
]
```

### Conditional Includes (Dev Only)
```python
from django.conf import settings

urlpatterns = [...]

if settings.DEBUG:
    import debug_toolbar
    urlpatterns = [
        path("__debug__/", include(debug_toolbar.urls)),
    ] + urlpatterns
```

## Anti-Patterns
- NEVER `include()` without `namespace=` — breaks reverse URL resolution
- NEVER nest includes more than 2 levels deep — keeps URLs debuggable
- NEVER duplicate URL prefixes across includes (two apps at `/blog/`)
- NEVER put view logic in URL files — import views, don't define them inline

## Red Flags
- Missing `app_name` in included app's `urls.py`
- URL prefix collision between two `include()` calls
- API URLs not under `/api/v1/` prefix

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `app/urls.py` — root URL configuration
- `apps/admin/urls.py` — admin panel URL imports
