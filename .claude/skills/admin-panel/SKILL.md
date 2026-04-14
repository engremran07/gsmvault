---
name: admin-panel
description: "Admin panel architecture and templates. Use when: creating admin views, admin templates, sidebar navigation, _render_admin pattern, CRUD pages, admin dashboard."
user-invocable: true
---

# Admin Panel Skill

## Architecture

8 view modules in `apps/admin/views_*.py`, namespace `admin_suite`. All views call `_render_admin()`.

```python
from .views_shared import _render_admin

def my_view(request):
    return _render_admin(
        request,
        "admin_suite/my_page.html",
        {"items": MyModel.objects.all()},
        nav_active="my_section",
        breadcrumb=[{"label": "Dashboard", "url": "/admin-suite/"}, {"label": "My Page"}],
    )
```

## Template Hierarchy

```
templates/base/_base.html
  └─ templates/layouts/admin.html          ← sidebar + content
      └─ templates/admin_suite/<page>.html ← individual pages
```

Page template skeleton:
```html
{% extends "layouts/admin.html" %}
{% block page_header %}My Page{% endblock %}
{% block content %}
  {# your content here — use _admin_kpi_card, _admin_table, _admin_search #}
{% endblock %}
```

Full detail: @.github/skills/admin-panel/SKILL.md
