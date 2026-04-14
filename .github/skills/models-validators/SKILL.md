---
name: models-validators
description: "Model-level validators, clean() method, ValidationError patterns. Use when: adding field validators, cross-field validation, custom validation logic."
---

# Model Validators

## When to Use
- Adding field-level constraints beyond what the field type provides
- Cross-field validation in `clean()` method
- Reusable validators shared across models
- Raising `ValidationError` with proper field-keyed messages

## Rules
- Validators go on the field definition: `validators=[my_validator]`
- Cross-field validation goes in `clean()` — not in `save()` or field validators
- Always call `super().clean()` at the start of overridden `clean()`
- `ValidationError` messages MUST be keyed to field names for form display
- Reusable validators go in `apps/<app>/validators.py` or `apps/core/validators.py`
- `full_clean()` is NOT called automatically on `save()` — call it explicitly or validate in forms/serializers

## Patterns

### Field-Level Validators
```python
from django.core.validators import (
    MinValueValidator, MaxValueValidator, MinLengthValidator,
    RegexValidator, FileExtensionValidator,
)

class Firmware(TimestampedModel):
    version = models.CharField(
        max_length=50,
        validators=[
            RegexValidator(
                regex=r"^\d+\.\d+(\.\d+)?$",
                message="Version must be in format X.Y or X.Y.Z",
            ),
        ],
    )
    file_size = models.BigIntegerField(
        validators=[MinValueValidator(1, "File size must be positive")],
    )
    file = models.FileField(
        upload_to="firmwares/",
        validators=[FileExtensionValidator(allowed_extensions=["zip", "rar", "7z", "bin"])],
    )
```

### Custom Reusable Validator
```python
# apps/core/validators.py
from django.core.exceptions import ValidationError

def validate_no_html(value: str) -> None:
    """Reject strings containing HTML tags."""
    if "<" in value and ">" in value:
        raise ValidationError("HTML tags are not allowed in this field.")

def validate_slug_format(value: str) -> None:
    """Enforce lowercase slug with hyphens only."""
    import re
    if not re.match(r"^[a-z0-9]+(?:-[a-z0-9]+)*$", value):
        raise ValidationError("Slug must be lowercase letters, numbers, and hyphens only.")

# Usage:
class Brand(TimestampedModel):
    name = models.CharField(max_length=255, validators=[validate_no_html])
    slug = models.SlugField(max_length=255, validators=[validate_slug_format])
```

### clean() for Cross-Field Validation
```python
from django.core.exceptions import ValidationError

class Campaign(TimestampedModel):
    start_at = models.DateTimeField()
    end_at = models.DateTimeField(null=True, blank=True)
    budget = models.DecimalField(max_digits=10, decimal_places=2)
    daily_cap = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    def clean(self) -> None:
        super().clean()
        errors: dict[str, list[str]] = {}

        if self.end_at and self.start_at and self.end_at <= self.start_at:
            errors.setdefault("end_at", []).append("End date must be after start date.")

        if self.daily_cap and self.budget and self.daily_cap > self.budget:
            errors.setdefault("daily_cap", []).append("Daily cap cannot exceed total budget.")

        if errors:
            raise ValidationError(errors)
```

### Validation in Services
```python
# apps/firmwares/services.py
from django.core.exceptions import ValidationError

def create_firmware(*, name: str, version: str, brand_id: int) -> Firmware:
    firmware = Firmware(name=name, version=version, brand_id=brand_id)
    firmware.full_clean()  # Triggers validators + clean()
    firmware.save()
    return firmware
```

### Image Dimension Validator
```python
def validate_image_dimensions(image: Any) -> None:
    from PIL import Image
    img = Image.open(image)
    width, height = img.size
    if width > 4096 or height > 4096:
        raise ValidationError(f"Image dimensions {width}x{height} exceed maximum 4096x4096.")
    if width < 100 or height < 100:
        raise ValidationError(f"Image dimensions {width}x{height} are below minimum 100x100.")
```

## Anti-Patterns
- Validating in `save()` instead of `clean()` — `save()` can skip validation
- Not calling `super().clean()` in overridden `clean()`
- Raising `ValidationError` without field key — errors won't map to form fields
- Trusting that `save()` calls `full_clean()` — it does NOT by default
- Duplicate validation in model AND form — validate in model, forms call `full_clean()`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Validators](https://docs.djangoproject.com/en/5.2/ref/validators/)
- [Django Model Validation](https://docs.djangoproject.com/en/5.2/ref/models/instances/#validating-objects)
