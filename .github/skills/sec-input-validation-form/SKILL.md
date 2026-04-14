---
name: sec-input-validation-form
description: "Form input validation: Django forms, clean methods. Use when: validating user input in forms, adding custom validators."
---

# Form Input Validation

## When to Use

- Creating Django forms with custom validation
- Adding field-level and cross-field validation
- Sanitizing form input before processing

## Rules

| Layer | Validator | Purpose |
|-------|-----------|---------|
| Field | `clean_<field>()` | Single field validation |
| Form | `clean()` | Cross-field validation |
| Model | `validators=[...]` | Database-level constraints |
| Template | `{{ form.errors }}` | Display errors to user |

## Patterns

### Field-Level Validation
```python
from django import forms
from django.core.exceptions import ValidationError

class FirmwareUploadForm(forms.Form):
    name = forms.CharField(max_length=200)
    description = forms.CharField(widget=forms.Textarea, max_length=5000)
    file = forms.FileField()

    def clean_name(self) -> str:
        name = self.cleaned_data["name"]
        if "<" in name or ">" in name:
            raise ValidationError("HTML tags not allowed in name.")
        return name.strip()

    def clean_file(self):
        f = self.cleaned_data["file"]
        max_size = 500 * 1024 * 1024  # 500 MB
        if f.size > max_size:
            raise ValidationError(f"File too large. Max {max_size // (1024*1024)} MB.")
        allowed = [".zip", ".rar", ".7z", ".bin", ".img"]
        ext = f.name.rsplit(".", 1)[-1].lower() if "." in f.name else ""
        if f".{ext}" not in allowed:
            raise ValidationError(f"File type .{ext} not allowed.")
        return f
```

### Cross-Field Validation
```python
class DateRangeForm(forms.Form):
    start_date = forms.DateField()
    end_date = forms.DateField()

    def clean(self) -> dict:
        cleaned = super().clean()
        start = cleaned.get("start_date")
        end = cleaned.get("end_date")
        if start and end and start >= end:
            raise ValidationError("End date must be after start date.")
        return cleaned
```

### Template Error Display
```html
{% if form.non_field_errors %}
    {% include "components/_form_errors.html" with errors=form.non_field_errors %}
{% endif %}
{% for field in form %}
    {% include "components/_form_field.html" with field=field %}
{% endfor %}
```

## Red Flags

- `request.POST.get()` without form validation
- No `max_length` on text inputs
- Missing file size/type validation
- Form errors not displayed to user
- Trusting `cleaned_data` without calling `is_valid()`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
