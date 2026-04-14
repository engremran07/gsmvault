---
name: forms-wizard
description: "Multi-step form wizards with session storage. Use when: complex multi-step forms, checkout flows, registration wizards, data entry across multiple pages."
---

# Multi-Step Form Wizards

## When to Use
- Registration flows with profile setup steps
- Firmware upload with metadata → file → review steps
- Checkout processes spanning multiple pages
- Data collection that benefits from progressive disclosure

## Rules
- Store intermediate data in session — not in hidden form fields
- Each step has its own form class — validate step-by-step
- Final step collects all session data and calls service layer
- Clean up session data after successful completion
- Support back-navigation without losing data

## Patterns

### Session-Based Wizard Views
```python
# apps/firmwares/views.py
WIZARD_SESSION_KEY = "firmware_upload_wizard"

@login_required
@require_http_methods(["GET", "POST"])
def upload_step1(request: HttpRequest) -> HttpResponse:
    """Step 1: Basic firmware info."""
    if request.method == "POST":
        form = FirmwareStep1Form(request.POST)
        if form.is_valid():
            wizard_data = request.session.get(WIZARD_SESSION_KEY, {})
            wizard_data["step1"] = form.cleaned_data
            request.session[WIZARD_SESSION_KEY] = wizard_data
            return redirect("firmwares:upload_step2")
    else:
        # Pre-fill from session if navigating back
        saved = request.session.get(WIZARD_SESSION_KEY, {}).get("step1", {})
        form = FirmwareStep1Form(initial=saved)

    return render(request, "firmwares/upload/step1.html", {
        "form": form, "current_step": 1, "total_steps": 3,
    })

@login_required
@require_http_methods(["GET", "POST"])
def upload_step2(request: HttpRequest) -> HttpResponse:
    """Step 2: File upload."""
    wizard_data = request.session.get(WIZARD_SESSION_KEY, {})
    if "step1" not in wizard_data:
        return redirect("firmwares:upload_step1")

    if request.method == "POST":
        form = FirmwareStep2Form(request.POST, request.FILES)
        if form.is_valid():
            # Store file reference (not the file itself)
            wizard_data["step2"] = {"filename": form.cleaned_data["file"].name}
            request.session[WIZARD_SESSION_KEY] = wizard_data
            # Save file temporarily
            handle_temp_upload(form.cleaned_data["file"], request.session.session_key)
            return redirect("firmwares:upload_step3")
    else:
        form = FirmwareStep2Form()

    return render(request, "firmwares/upload/step2.html", {
        "form": form, "current_step": 2, "total_steps": 3,
    })

@login_required
@require_http_methods(["GET", "POST"])
def upload_step3(request: HttpRequest) -> HttpResponse:
    """Step 3: Review and confirm."""
    wizard_data = request.session.get(WIZARD_SESSION_KEY, {})
    if "step1" not in wizard_data or "step2" not in wizard_data:
        return redirect("firmwares:upload_step1")

    if request.method == "POST":
        # Final submission — delegate to service
        firmware = create_firmware_from_wizard(
            user=request.user,
            wizard_data=wizard_data,
            session_key=request.session.session_key,
        )
        # Clean up session
        del request.session[WIZARD_SESSION_KEY]
        messages.success(request, "Firmware uploaded successfully!")
        return redirect("firmwares:detail", pk=firmware.pk)

    return render(request, "firmwares/upload/step3.html", {
        "wizard_data": wizard_data, "current_step": 3, "total_steps": 3,
    })
```

### Step Forms
```python
class FirmwareStep1Form(forms.Form):
    name = forms.CharField(max_length=255, widget=forms.TextInput(attrs={"class": "form-input"}))
    brand = forms.ModelChoiceField(queryset=Brand.objects.all(), widget=forms.Select(attrs={"class": "form-select"}))
    version = forms.CharField(max_length=50)
    firmware_type = forms.ChoiceField(choices=FirmwareType.choices)
    description = forms.CharField(widget=forms.Textarea(attrs={"rows": 4}), required=False)

class FirmwareStep2Form(forms.Form):
    file = forms.FileField(widget=forms.FileInput(attrs={"accept": ".zip,.rar,.7z,.bin"}))

    def clean_file(self) -> Any:
        file = self.cleaned_data["file"]
        if file.size > 500 * 1024 * 1024:
            raise forms.ValidationError("File cannot exceed 500 MB.")
        return file
```

### Progress Indicator Template
```html
<!-- templates/firmwares/upload/base_wizard.html -->
{% extends "layouts/default.html" %}
{% block content %}
<div class="wizard-progress">
    {% for step in "123" %}
    <div class="wizard-step {% if forloop.counter == current_step %}active{% elif forloop.counter < current_step %}completed{% endif %}">
        <span class="step-number">{{ forloop.counter }}</span>
        <span class="step-label">
            {% if forloop.counter == 1 %}Details{% elif forloop.counter == 2 %}Upload{% else %}Review{% endif %}
        </span>
    </div>
    {% endfor %}
</div>

{% block wizard_content %}{% endblock %}
{% endblock %}
```

### URL Configuration
```python
# apps/firmwares/urls.py
urlpatterns = [
    path("upload/", views.upload_step1, name="upload_step1"),
    path("upload/file/", views.upload_step2, name="upload_step2"),
    path("upload/review/", views.upload_step3, name="upload_step3"),
]
```

## Anti-Patterns
- Storing sensitive data in hidden fields — use server-side sessions
- Not validating step order — user could skip to step 3 directly
- Storing uploaded files in session — session backends have size limits
- Not cleaning up session after completion — stale data accumulates
- Missing back-navigation support — user loses data going back

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Sessions](https://docs.djangoproject.com/en/5.2/topics/http/sessions/)
