---
name: admin-widgets
description: "Admin widget customization: autocomplete, raw_id_fields, filter_horizontal. Use when: optimizing FK selects, adding autocomplete search, horizontal filter for M2M."
---

# Admin Widgets

## When to Use
- FK dropdown has too many options (100+) — switch to autocomplete or raw_id
- M2M field needs a better selection UI than the default multi-select
- Date/time fields need a picker widget
- Rich text editing in admin forms

## Rules
- Use `autocomplete_fields` for FK/M2M fields with 50+ options
- Models used in `autocomplete_fields` MUST have `search_fields` defined
- Use `raw_id_fields` for FK fields where autocomplete isn't helpful
- Use `filter_horizontal` for M2M with moderate options (10-200)
- Use `filter_vertical` for M2M on narrow admin pages
- NEVER use default `<select>` for FK fields with thousands of records

## Patterns

### Autocomplete Fields
```python
@admin.register(Firmware)
class FirmwareAdmin(admin.ModelAdmin[Firmware]):
    # These FK fields get autocomplete search instead of dropdown
    autocomplete_fields = ("brand", "model", "uploaded_by")
    # The referenced models MUST define search_fields:
    # class BrandAdmin: search_fields = ("name",)


@admin.register(Brand)
class BrandAdmin(admin.ModelAdmin[Brand]):
    search_fields = ("name",)  # Required for autocomplete to work
```

### Raw ID Fields
```python
@admin.register(DownloadToken)
class DownloadTokenAdmin(admin.ModelAdmin[DownloadToken]):
    # Shows as text input with lookup popup — good for infrequent lookups
    raw_id_fields = ("user", "firmware")
    list_display = ("token", "user", "firmware", "status", "expires_at")
```

### Filter Horizontal (M2M)
```python
@admin.register(ForumTopic)
class ForumTopicAdmin(admin.ModelAdmin[ForumTopic]):
    # Dual-pane selector for M2M fields
    filter_horizontal = ("tags",)
    # Or vertical layout:
    # filter_vertical = ("tags",)
```

### Custom Widgets via formfield_overrides
```python
from django.db import models

@admin.register(BlogPost)
class BlogPostAdmin(admin.ModelAdmin[BlogPost]):
    formfield_overrides = {
        models.TextField: {
            "widget": admin.widgets.AdminTextareaWidget(attrs={"rows": 5}),
        },
        models.URLField: {
            "widget": admin.widgets.AdminURLFieldWidget,
        },
    }
```

### Widget Customization per Field
```python
from django.contrib.admin.widgets import AdminDateWidget

@admin.register(Campaign)
class CampaignAdmin(admin.ModelAdmin[Campaign]):

    def formfield_for_dbfield(self, db_field: models.Field, request: HttpRequest, **kwargs):  # type: ignore[type-arg]
        if db_field.name in ("start_at", "end_at"):
            kwargs["widget"] = AdminDateWidget(attrs={"class": "vDateField"})
        return super().formfield_for_dbfield(db_field, request, **kwargs)
```

### Readonly Display Widgets
```python
@admin.register(SecurityEvent)
class SecurityEventAdmin(admin.ModelAdmin[SecurityEvent]):
    readonly_fields = ("event_type", "ip_address", "user_agent", "created_at", "details_display")
    list_display = ("event_type", "ip_address", "created_at")

    @admin.display(description="Event Details")
    def details_display(self, obj: SecurityEvent) -> str:
        import json
        if obj.details:
            return json.dumps(obj.details, indent=2)
        return "-"
```

## Anti-Patterns
- NEVER use default `<select>` for FK with 1000+ records — causes admin timeout
- NEVER use `autocomplete_fields` without `search_fields` on the target model
- NEVER use `filter_horizontal` for M2M with 1000+ options — use autocomplete
- NEVER override widget CSS in admin — use Django's built-in widget classes

## Red Flags
- Admin page takes 5+ seconds to load — likely a FK dropdown loading all records
- `autocomplete_fields` pointing to model without `search_fields`
- `filter_horizontal` on a field with thousands of options

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `apps/*/admin.py` — existing widget configurations
