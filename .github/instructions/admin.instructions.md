---
applyTo: 'apps/*/admin.py, apps/admin/views*.py'
---

# Admin Panel Conventions

## ModelAdmin Typing

ModelAdmin classes MUST be typed with the model generic:

```python
from django.contrib import admin
from .models import Firmware

@admin.register(Firmware)
class FirmwareAdmin(admin.ModelAdmin[Firmware]):
    list_display = ["name", "brand", "status", "created_at"]
    list_filter = ["status", "brand"]
    search_fields = ["name", "description"]
    ordering = ["-created_at"]
    readonly_fields = ["created_at", "updated_at"]

    def get_queryset(self, request: HttpRequest) -> QuerySet[Firmware]:
        return super().get_queryset(request).select_related("brand", "model")
```

## Custom Admin Views

Admin views in `apps/admin/views_*.py` use the shared helper:

```python
from .views_shared import *  # noqa: F403

@login_required
@user_passes_test(lambda u: u.is_staff)
def admin_firmware_list(request: HttpRequest) -> HttpResponse:
    firmwares = Firmware.objects.select_related("brand").all()
    context = {"firmwares": firmwares, "total": firmwares.count()}
    breadcrumbs = [("Dashboard", "/admin/"), ("Firmwares", None)]
    return _render_admin(request, "admin/firmwares/list.html", context, breadcrumbs)
```

Rules:
- Always use `_render_admin()` — never call `render()` directly
- Always decorate with `@login_required` + `@user_passes_test(lambda u: u.is_staff)`
- The admin app is the ONLY app allowed to import models from ALL other apps

## Admin View Modules

8 view modules in `apps/admin/`:
- `views_auth.py` — authentication management
- `views_content.py` — blog, pages, comments, tags
- `views_distribution.py` — social/content syndication
- `views_extended.py` — forum, gamification, bounty, marketplace
- `views_infrastructure.py` — storage, backup, analytics, API
- `views_security.py` — WAF, rate limits, blocked IPs, crawlers
- `views_settings.py` — site settings, consent, SEO
- `views_users.py` — user management, profiles, devices

All import from `views_shared.py`: `from .views_shared import *`

## Admin Template Components

ALWAYS use reusable components — never inline HTML:

```html
<!-- KPI cards -->
{% include "components/_admin_kpi_card.html" with title="Total Firmwares" value=total icon="hard-drive" %}

<!-- Search bar -->
{% include "components/_admin_search.html" with placeholder="Search firmwares..." %}

<!-- Data table -->
{% include "components/_admin_table.html" with headers=headers rows=rows %}

<!-- Bulk actions -->
{% include "components/_admin_bulk_actions.html" with actions=actions %}
```

## Admin List Display

Use `list_display` with descriptive callables:

```python
@admin.register(Firmware)
class FirmwareAdmin(admin.ModelAdmin[Firmware]):
    list_display = ["name", "brand_name", "status_badge", "download_count", "created_at"]

    @admin.display(description="Brand", ordering="brand__name")
    def brand_name(self, obj: Firmware) -> str:
        return obj.brand.name

    @admin.display(description="Status", ordering="status")
    def status_badge(self, obj: Firmware) -> str:
        colors = {"approved": "green", "pending": "yellow", "rejected": "red"}
        return format_html('<span class="badge {}">{}</span>', colors.get(obj.status, "gray"), obj.status)
```

## get_queryset Optimization

Always optimize queries with `select_related` / `prefetch_related`:

```python
def get_queryset(self, request: HttpRequest) -> QuerySet[Firmware]:
    return (
        super()
        .get_queryset(request)
        .select_related("brand", "model", "user")
        .prefetch_related("tags")
    )
```
