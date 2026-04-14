---
applyTo: 'apps/*/forms.py'
---

# Django Form Conventions

## Use ModelForm When Possible

```python
from django import forms
from .models import Firmware

class FirmwareForm(forms.ModelForm):
    class Meta:
        model = Firmware
        fields = ["name", "description", "brand", "model", "file"]
        widgets = {
            "description": forms.Textarea(attrs={"rows": 4, "class": "form-input"}),
            "name": forms.TextInput(attrs={"class": "form-input", "placeholder": "Firmware name"}),
        }
        error_messages = {
            "name": {"required": "Firmware name is required."},
            "file": {"required": "Please upload a firmware file."},
        }
```

## Field-Level Validation

Use `clean_fieldname()` for single-field validation:

```python
def clean_name(self) -> str:
    name = self.cleaned_data["name"]
    if len(name) < 3:
        raise forms.ValidationError("Name must be at least 3 characters.")
    return name

def clean_file(self) -> UploadedFile:
    file = self.cleaned_data["file"]
    max_size = 500 * 1024 * 1024  # 500MB
    if file.size > max_size:
        raise forms.ValidationError(f"File too large. Maximum is {max_size // (1024*1024)}MB.")
    return file
```

## Cross-Field Validation

Use `clean()` for validation that spans multiple fields:

```python
def clean(self) -> dict[str, Any]:
    cleaned_data = super().clean()
    start_date = cleaned_data.get("start_date")
    end_date = cleaned_data.get("end_date")
    if start_date and end_date and start_date >= end_date:
        raise forms.ValidationError("End date must be after start date.")
    return cleaned_data
```

## HTML Content Sanitization

All user-supplied HTML fields MUST be sanitized using nh3-based sanitizer:

```python
from apps.core.sanitizers import sanitize_html_content

def clean_description(self) -> str:
    description = self.cleaned_data["description"]
    return sanitize_html_content(description)

def clean_bio(self) -> str:
    bio = self.cleaned_data["bio"]
    return sanitize_html_content(bio)
```

Never use `bleach` — it has been replaced by `nh3` (Rust-based, OWASP XSS safe).

## File Upload Validation

Validate MIME type, extension, and file size:

```python
import mimetypes

ALLOWED_EXTENSIONS = {".zip", ".rar", ".7z", ".tar.gz", ".bin"}
ALLOWED_MIMES = {"application/zip", "application/x-rar-compressed", "application/octet-stream"}

def clean_file(self) -> UploadedFile:
    file = self.cleaned_data["file"]
    ext = os.path.splitext(file.name)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise forms.ValidationError(f"Unsupported file type: {ext}")
    if file.content_type not in ALLOWED_MIMES:
        raise forms.ValidationError(f"Invalid content type: {file.content_type}")
    return file
```

## Error Messages

Always provide user-friendly error messages:

```python
class Meta:
    error_messages = {
        "name": {
            "required": "Please enter a name.",
            "max_length": "Name cannot exceed 255 characters.",
            "unique": "This name is already taken.",
        },
    }
```

## Form Rendering

Use the `_form_field` and `_field_error` components in templates:

```html
{% include "components/_form_field.html" with field=form.name %}
{% include "components/_form_errors.html" with form=form %}
```

## Type Hints

Type hint return values of clean methods:

```python
def clean_email(self) -> str:
    ...

def clean(self) -> dict[str, Any]:
    ...
```
