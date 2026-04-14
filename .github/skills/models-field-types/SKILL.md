---
name: models-field-types
description: "Field type selection guide: CharField vs TextField, JSONField, ArrayField, etc. Use when: choosing field types, configuring field options, using PostgreSQL-specific fields."
---

# Model Field Types

## When to Use
- Choosing between similar field types (CharField vs TextField, etc.)
- Using PostgreSQL-specific fields (JSONField, ArrayField, CITextField)
- Configuring field options (blank, null, default, choices)
- Understanding field type performance implications

## Rules
- `null=True` on string fields is almost always wrong — use `blank=True, default=""`
- `JSONField` requires PostgreSQL — already our database, so always available
- `choices` use tuple-of-tuples or `models.TextChoices` / `models.IntegerChoices`
- `DecimalField` for money — NEVER `FloatField` for financial data
- `GenericIPAddressField` for IPs — never `CharField`
- Every FK/M2M MUST have `related_name`

## Patterns

### String Fields — When to Use Which

| Field | Max Length | Use For |
|---|---|---|
| `CharField(max_length=N)` | Required | Short text: names, slugs, codes, statuses |
| `TextField()` | Unlimited | Long text: descriptions, content, HTML |
| `SlugField(max_length=N)` | Required | URL slugs (auto-validates slug format) |
| `EmailField()` | 254 | Email addresses |
| `URLField()` | 200 | URLs |

```python
class Firmware(TimestampedModel):
    name = models.CharField(max_length=255)           # short, indexed
    slug = models.SlugField(max_length=255, unique=True)
    description = models.TextField(blank=True, default="")  # long, not indexed
    version = models.CharField(max_length=50)
    download_url = models.URLField(max_length=500, blank=True, default="")
```

### Choices with TextChoices Enum
```python
class FirmwareType(models.TextChoices):
    OFFICIAL = "official", "Official"
    ENGINEERING = "engineering", "Engineering"
    READBACK = "readback", "Readback"
    MODIFIED = "modified", "Modified"
    OTHER = "other", "Other"

class Firmware(TimestampedModel):
    firmware_type = models.CharField(
        max_length=20,
        choices=FirmwareType.choices,
        default=FirmwareType.OFFICIAL,
    )
```

### Numeric Fields

| Field | Use For |
|---|---|
| `IntegerField` | Counts, quantities |
| `PositiveIntegerField` | Non-negative counts |
| `DecimalField(max_digits, decimal_places)` | Money, precise decimals |
| `FloatField` | Scientific data (NEVER money) |
| `BigIntegerField` | File sizes in bytes |

```python
class Product(TimestampedModel):
    price = models.DecimalField(max_digits=10, decimal_places=2)  # money
    stock = models.PositiveIntegerField(default=0)
    file_size = models.BigIntegerField(default=0)  # bytes
```

### JSONField — Flexible Schema
```python
class DeviceConfig(TimestampedModel):
    """Singleton config — uses JSONField for nested settings."""
    fingerprinting_policy = models.JSONField(default=dict, blank=True)
    quota_overrides = models.JSONField(default=dict, blank=True)

    # Query JSONField:
    # DeviceConfig.objects.filter(fingerprinting_policy__enabled=True)
```

### Date/Time Fields
```python
class Campaign(TimestampedModel):
    start_at = models.DateTimeField()
    end_at = models.DateTimeField(null=True, blank=True)  # null OK for optional dates
    launch_date = models.DateField(null=True, blank=True)
```

### File Fields
```python
class FirmwareFile(TimestampedModel):
    file = models.FileField(upload_to="firmwares/%Y/%m/")
    image = models.ImageField(upload_to="images/", blank=True)
    # Always validate MIME type and size in services.py before saving
```

### null vs blank Cheat Sheet

| Field Type | `null=True` | `blank=True` | Correct Pattern |
|---|---|---|---|
| CharField / TextField | **NO** | Yes | `blank=True, default=""` |
| IntegerField | Yes (if optional) | Yes | `null=True, blank=True` |
| ForeignKey | Yes (if optional) | Yes | `null=True, blank=True, on_delete=SET_NULL` |
| DateTimeField | Yes (if optional) | Yes | `null=True, blank=True` |
| BooleanField | **NO** | No | `default=False` |
| JSONField | **NO** | Yes | `default=dict, blank=True` |

## Anti-Patterns
- `null=True` on `CharField` / `TextField` — use `default=""` instead
- `FloatField` for prices or currency — always `DecimalField`
- Missing `related_name` on FK/M2M — causes clash errors
- `CharField` for IP addresses — use `GenericIPAddressField`
- Hard-coded choice strings — use `TextChoices` enum

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Model Field Reference](https://docs.djangoproject.com/en/5.2/ref/models/fields/)
