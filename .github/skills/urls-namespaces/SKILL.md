---
name: urls-namespaces
description: "URL namespace patterns: app_name, include(), reverse(). Use when: configuring URL namespaces, setting up app_name, debugging NoReverseMatch errors."
---

# URL Namespaces

## When to Use
- Setting up URL routing for a new or existing Django app
- Debugging `NoReverseMatch` errors related to namespaces
- Adding `include()` with proper namespace binding
- Using `reverse()` or `{% url %}` with namespaced routes

## Rules
- Every app MUST define `app_name` in its `urls.py`
- Root `app/urls.py` MUST use `namespace=` matching `app_name`
- All template URL references use `{% url "namespace:name" %}`
- All Python URL references use `reverse("namespace:name")`
- Admin panel uses `custom_admin` namespace

## Patterns

### App-Level urls.py
```python
# apps/firmwares/urls.py
from django.urls import path

from . import views

app_name = "firmwares"

urlpatterns = [
    path("", views.firmware_list, name="list"),
    path("<int:pk>/", views.firmware_detail, name="detail"),
    path("<int:pk>/download/", views.firmware_download, name="download"),
]
```

### Root URL Include
```python
# app/urls.py
from django.urls import include, path

urlpatterns = [
    path("firmwares/", include("apps.firmwares.urls", namespace="firmwares")),
    path("blog/", include("apps.blog.urls", namespace="blog")),
    path("forum/", include("apps.forum.urls", namespace="forum")),
    path("api/v1/", include("apps.api.urls", namespace="api")),
]
```

### Reverse in Views
```python
from django.urls import reverse

def approve_firmware(request: HttpRequest, pk: int) -> HttpResponse:
    # ...
    return redirect(reverse("firmwares:detail", kwargs={"pk": pk}))
```

### Template Usage
```html
<a href="{% url 'firmwares:detail' pk=fw.pk %}">{{ fw.name }}</a>
<form action="{% url 'firmwares:download' pk=fw.pk %}" method="post">
```

### Nested Namespaces (API)
```python
# apps/api/urls.py
app_name = "api"

urlpatterns = [
    path("firmwares/", include("apps.firmwares.api_urls", namespace="firmwares")),
]
# Usage: reverse("api:firmwares:list")
```

## Anti-Patterns
- NEVER omit `app_name` — causes `NoReverseMatch` at runtime
- NEVER mismatch `namespace=` in include with `app_name` in the app
- NEVER hardcode URLs: `/firmwares/42/` — always use `{% url %}` or `reverse()`
- NEVER use the same namespace for two different apps

## Red Flags
- `NoReverseMatch` errors — check `app_name` and `namespace` match
- Missing `name=` on URL patterns — every pattern needs a name
- Duplicate namespaces in `app/urls.py`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `app/urls.py` — root URL configuration
- `.claude/rules/urls-layer.md` — URL layer rules
