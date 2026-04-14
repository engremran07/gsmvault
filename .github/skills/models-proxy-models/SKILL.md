---
name: models-proxy-models
description: "Proxy model patterns for polymorphic behavior without new tables. Use when: adding model-level behavior variants, custom managers per type, admin registrations per subtype."
---

# Proxy Models

## When to Use
- Different behavior for subsets of the same table (e.g., published vs draft posts)
- Separate admin registrations for the same underlying table
- Custom default managers per type without schema changes
- Polymorphic read patterns without multi-table inheritance overhead

## Rules
- Proxy models MUST set `proxy = True` in Meta — otherwise Django creates a new table
- Proxy models inherit the parent's `db_table` — never set a different one
- Custom managers on proxy models filter automatically — use for type-scoped queries
- Proxy models CAN have their own `ModelAdmin` registration
- Never add database fields to proxy models — only methods and managers

## Patterns

### Type-Scoped Proxy with Custom Manager
```python
from apps.core.models import TimestampedModel

class Firmware(TimestampedModel):
    name = models.CharField(max_length=255)
    firmware_type = models.CharField(
        max_length=20,
        choices=[
            ("official", "Official"),
            ("engineering", "Engineering"),
            ("modified", "Modified"),
        ],
    )

    class Meta:
        db_table = "firmwares_firmware"

class OfficialFirmwareManager(models.Manager["OfficialFirmware"]):
    def get_queryset(self) -> models.QuerySet["OfficialFirmware"]:
        return super().get_queryset().filter(firmware_type="official")

class OfficialFirmware(Firmware):
    objects = OfficialFirmwareManager()

    class Meta:
        proxy = True
        verbose_name = "Official Firmware"
        verbose_name_plural = "Official Firmwares"

    def save(self, *args: Any, **kwargs: Any) -> None:
        self.firmware_type = "official"
        super().save(*args, **kwargs)
```

### Separate Admin for Proxy
```python
from django.contrib import admin

@admin.register(OfficialFirmware)
class OfficialFirmwareAdmin(admin.ModelAdmin["OfficialFirmware"]):
    list_display = ("name", "version", "created_at")
    list_filter = ("brand",)

    def get_queryset(self, request: HttpRequest) -> QuerySet[OfficialFirmware]:
        return super().get_queryset(request).select_related("brand")
```

### Behavior Variants via Proxy
```python
class SecurityEvent(TimestampedModel):
    event_type = models.CharField(max_length=50)
    severity = models.CharField(max_length=20)
    ip_address = models.GenericIPAddressField()

    class Meta:
        db_table = "security_securityevent"

class CriticalSecurityEvent(SecurityEvent):
    """Proxy for critical events — adds notification behavior."""
    class Meta:
        proxy = True

    def notify_admins(self) -> None:
        """Send alert for critical security events."""
        # Business logic here or delegate to services.py
        ...
```

### Status-Based Proxy Pattern
```python
class PublishedPostManager(models.Manager["PublishedPost"]):
    def get_queryset(self) -> models.QuerySet["PublishedPost"]:
        return super().get_queryset().filter(status="published")

class PublishedPost(BlogPost):
    objects = PublishedPostManager()

    class Meta:
        proxy = True
        verbose_name = "Published Post"
```

## Anti-Patterns
- Adding fields to proxy models — they cannot have database fields
- Forgetting `proxy = True` — creates a multi-table inheritance join
- Using proxy models when you actually need different columns — use abstract bases instead
- Creating too many proxy models — only use when behavior genuinely differs

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Proxy Models](https://docs.djangoproject.com/en/5.2/topics/db/models/#proxy-models)
