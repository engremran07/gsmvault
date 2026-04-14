---
name: admin-inlines
description: "TabularInline, StackedInline for related model editing. Use when: editing parent-child models together in admin, adding inline formsets to admin pages."
---

# Admin Inlines

## When to Use
- Editing child models alongside the parent in Django admin
- Adding firmware variants on the firmware edit page
- Editing poll choices inline with a poll
- Managing related records without navigating away

## Rules
- Use `TabularInline` for compact rows (3-5 fields per child)
- Use `StackedInline` for complex children with many fields
- ALWAYS type inlines: `class MyInline(admin.TabularInline[ChildModel, ParentModel]):`
- Set `extra = 0` to avoid empty form clutter — use "Add another" button
- Set `min_num` only if children are truly required
- Use `autocomplete_fields` for FK fields with many options

## Patterns

### TabularInline (Compact)
```python
from django.contrib import admin

from .models import ForumPoll, ForumPollChoice


class ForumPollChoiceInline(admin.TabularInline[ForumPollChoice, ForumPoll]):
    model = ForumPollChoice
    extra = 0
    min_num = 2  # A poll needs at least 2 choices
    fields = ("text", "sort_order")


@admin.register(ForumPoll)
class ForumPollAdmin(admin.ModelAdmin[ForumPoll]):
    inlines = [ForumPollChoiceInline]
    list_display = ("question", "topic", "poll_type", "is_active")
```

### StackedInline (Detailed)
```python
from .models import AdCreative, Campaign


class AdCreativeInline(admin.StackedInline[AdCreative, Campaign]):
    model = AdCreative
    extra = 0
    fields = ("title", "body", "image", "cta_url", "is_active")
    readonly_fields = ("click_count", "impression_count")
    classes = ("collapse",)  # Collapsible section
```

### Read-Only Inline (Audit Logs)
```python
class FieldChangeInline(admin.TabularInline[FieldChange, AuditLog]):
    model = FieldChange
    extra = 0
    readonly_fields = ("field_name", "old_value", "new_value")
    can_delete = False

    def has_add_permission(self, request: HttpRequest, obj: AuditLog | None = None) -> bool:
        return False
```

### Inline with Autocomplete
```python
class AffiliateProductInline(admin.TabularInline[AffiliateProduct, AffiliateProvider]):
    model = AffiliateProduct
    extra = 0
    autocomplete_fields = ("category",)
    fields = ("name", "category", "price", "commission_rate", "is_active")
```

### Limiting Displayed Inlines
```python
class ReplyInline(admin.TabularInline[ForumReply, ForumTopic]):
    model = ForumReply
    extra = 0
    max_num = 20  # Don't load 1000 replies in admin
    fields = ("author", "content_preview", "created_at")
    readonly_fields = ("content_preview", "created_at")

    @admin.display(description="Content")
    def content_preview(self, obj: ForumReply) -> str:
        return obj.content[:100] + "..." if len(obj.content) > 100 else obj.content
```

## Anti-Patterns
- NEVER set `extra = 3` or higher — clutters the form with empty rows
- NEVER use inlines for thousands of related records — use a separate admin page with filters
- NEVER omit type parameters on inline classes
- NEVER put complex logic in inline `save_model` — delegate to services

## Red Flags
- `extra = 3` (default) left unchanged — set to `0`
- Inline without `max_num` on a model that could have hundreds of children
- FK fields without `autocomplete_fields` or `raw_id_fields`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `apps/*/admin.py` — existing inline registrations
