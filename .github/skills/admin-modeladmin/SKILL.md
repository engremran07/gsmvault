---
name: admin-modeladmin
description: "ModelAdmin configuration: list_display, search_fields, list_filter, typed generics. Use when: registering models in Django admin, customizing admin list views, adding admin configuration."
---

# ModelAdmin Configuration

## When to Use
- Registering a model in Django's admin interface
- Customizing list display, search, filtering for admin
- Adding readonly fields, fieldsets, or custom display methods
- Configuring the Django admin for any app model

## Rules
- ALWAYS type ModelAdmin: `class MyAdmin(admin.ModelAdmin[MyModel]):`
- ALWAYS annotate `get_queryset` return type: `-> QuerySet[MyModel]`
- Use `list_display` for column visibility — never rely on `__str__` alone
- Use `search_fields` for fast text search (prefix with `^` for starts-with)
- Use `list_filter` for sidebar filters
- Set `ordering` explicitly — don't rely on model Meta ordering

## Patterns

### Basic ModelAdmin
```python
from django.contrib import admin
from django.db.models import QuerySet

from .models import Firmware


@admin.register(Firmware)
class FirmwareAdmin(admin.ModelAdmin[Firmware]):
    list_display = ("name", "brand", "model", "firmware_type", "is_active", "created_at")
    list_filter = ("firmware_type", "is_active", "brand")
    search_fields = ("name", "brand__name", "model__name")
    readonly_fields = ("created_at", "updated_at")
    ordering = ("-created_at",)
    list_per_page = 50
    date_hierarchy = "created_at"

    def get_queryset(self, request: HttpRequest) -> QuerySet[Firmware]:
        return super().get_queryset(request).select_related("brand", "model")
```

### Custom Display Methods
```python
@admin.register(DownloadToken)
class DownloadTokenAdmin(admin.ModelAdmin[DownloadToken]):
    list_display = ("token_short", "user", "firmware", "status", "expires_at")

    @admin.display(description="Token", ordering="token")
    def token_short(self, obj: DownloadToken) -> str:
        return str(obj.token)[:8] + "..."
```

### Fieldsets for Organized Forms
```python
@admin.register(Campaign)
class CampaignAdmin(admin.ModelAdmin[Campaign]):
    fieldsets = (
        ("Campaign Info", {
            "fields": ("name", "status", "campaign_type"),
        }),
        ("Budget", {
            "fields": ("daily_budget", "total_budget", "spent"),
        }),
        ("Schedule", {
            "fields": ("start_at", "end_at"),
            "classes": ("collapse",),
        }),
    )
```

### Optimized QuerySets
```python
@admin.register(ForumTopic)
class ForumTopicAdmin(admin.ModelAdmin[ForumTopic]):
    list_display = ("title", "category", "author", "reply_count", "created_at")
    list_select_related = ("category", "author")

    def get_queryset(self, request: HttpRequest) -> QuerySet[ForumTopic]:
        qs = super().get_queryset(request)
        return qs.select_related("category", "author").annotate(
            reply_count=Count("replies")  # type: ignore[attr-defined]
        )
```

## Anti-Patterns
- NEVER use untyped `admin.ModelAdmin` — always `admin.ModelAdmin[MyModel]`
- NEVER omit `select_related` on querysets with FK fields in `list_display`
- NEVER add expensive computed columns without database annotation
- NEVER leave `search_fields` empty on models with hundreds of records
- NEVER register the same model twice

## Red Flags
- `list_display` includes FK fields without `list_select_related`
- Missing type parameter on ModelAdmin class
- `get_queryset` without return type annotation

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `.claude/rules/django-models.md` — model conventions
- `apps/*/admin.py` — existing admin registrations
