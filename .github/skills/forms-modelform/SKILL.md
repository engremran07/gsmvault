---
name: forms-modelform
description: "ModelForm patterns: Meta fields, widgets, clean methods. Use when: creating forms from models, customizing form fields, overriding widgets."
---

# ModelForm Patterns

## When to Use
- Creating HTML forms tied to Django models
- Customizing field widgets (date pickers, textareas, selects)
- Adding form-level validation on top of model validation
- Processing user input before saving to database

## Rules
- Always explicitly list fields in `Meta.fields` — never `fields = "__all__"`
- Widget customization in `Meta.widgets` dictionary
- Form-level validation in `clean()` and `clean_<fieldname>()` methods
- Forms handle presentation — models handle data integrity
- Save logic goes through `services.py`, not `form.save()` directly in views

## Patterns

### Basic ModelForm
```python
from django import forms
from .models import Firmware

class FirmwareForm(forms.ModelForm):
    class Meta:
        model = Firmware
        fields = ["name", "description", "version", "firmware_type", "brand", "file"]
        widgets = {
            "name": forms.TextInput(attrs={
                "class": "form-input",
                "placeholder": "Firmware name",
            }),
            "description": forms.Textarea(attrs={
                "class": "form-textarea",
                "rows": 4,
                "placeholder": "Describe this firmware...",
            }),
            "firmware_type": forms.Select(attrs={"class": "form-select"}),
        }
        labels = {
            "firmware_type": "Type",
        }
        help_texts = {
            "version": "Format: X.Y or X.Y.Z",
        }
```

### Field-Level Validation
```python
class FirmwareForm(forms.ModelForm):
    class Meta:
        model = Firmware
        fields = ["name", "version", "file"]

    def clean_version(self) -> str:
        version = self.cleaned_data["version"].strip()
        import re
        if not re.match(r"^\d+\.\d+(\.\d+)?$", version):
            raise forms.ValidationError("Version must be in format X.Y or X.Y.Z")
        return version

    def clean_file(self) -> Any:
        file = self.cleaned_data.get("file")
        if file:
            if file.size > 500 * 1024 * 1024:  # 500 MB
                raise forms.ValidationError("File size cannot exceed 500 MB.")
            allowed = [".zip", ".rar", ".7z", ".bin"]
            ext = Path(file.name).suffix.lower()
            if ext not in allowed:
                raise forms.ValidationError(f"File type {ext} not allowed. Use: {', '.join(allowed)}")
        return file
```

### Cross-Field Validation
```python
class CampaignForm(forms.ModelForm):
    class Meta:
        model = Campaign
        fields = ["name", "start_at", "end_at", "budget", "daily_cap"]
        widgets = {
            "start_at": forms.DateTimeInput(attrs={"type": "datetime-local"}),
            "end_at": forms.DateTimeInput(attrs={"type": "datetime-local"}),
        }

    def clean(self) -> dict[str, Any]:
        cleaned = super().clean()
        start = cleaned.get("start_at")
        end = cleaned.get("end_at")
        if start and end and end <= start:
            self.add_error("end_at", "End date must be after start date.")
        return cleaned
```

### Using in View (Service Delegation)
```python
@require_http_methods(["GET", "POST"])
@login_required
def create_firmware(request: HttpRequest) -> HttpResponse:
    if request.method == "POST":
        form = FirmwareForm(request.POST, request.FILES)
        if form.is_valid():
            # Delegate to service — don't call form.save() here
            firmware = create_firmware_entry(
                uploaded_by=request.user,
                **form.cleaned_data,
            )
            messages.success(request, "Firmware uploaded successfully.")
            return redirect("firmwares:detail", pk=firmware.pk)
    else:
        form = FirmwareForm()

    return render(request, "firmwares/create.html", {"form": form})
```

### Rendering with Component
```html
<form method="post" enctype="multipart/form-data">
    {% csrf_token %}
    {% include "components/_form_errors.html" with form=form %}

    {% for field in form %}
        {% include "components/_form_field.html" with field=field %}
    {% endfor %}

    <button type="submit" class="btn btn-primary">Upload Firmware</button>
</form>
```

## Anti-Patterns
- `fields = "__all__"` — exposes all model fields, including internal ones
- Business logic in `form.save()` override — use service layer
- Not handling `request.FILES` for file upload forms — files won't be received
- Missing `enctype="multipart/form-data"` on forms with file uploads
- Inline form HTML — use `{% include "components/_form_field.html" %}`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django ModelForm](https://docs.djangoproject.com/en/5.2/topics/forms/modelforms/)
- `templates/components/_form_field.html` — reusable form field component
