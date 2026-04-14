---
name: forms-validation
description: "Form validation: clean_fieldname, clean, ValidationError, error_messages. Use when: adding custom validation, cross-field checks, displaying errors."
---

# Form Validation

## When to Use
- Adding custom validation beyond field type constraints
- Cross-field validation (passwords match, date ranges)
- Custom error messages for better UX
- Validating before delegating to service layer
- Sanitizing user input in forms

## Rules
- `clean_<fieldname>()` for single-field validation — returns cleaned value
- `clean()` for cross-field validation — returns `cleaned_data` dict
- Use `self.add_error("field", "message")` over raising in `clean()`
- Render errors with `{% include "components/_form_errors.html" %}` and `{% include "components/_field_error.html" %}`
- Sanitize HTML input with `apps.core.sanitizers.sanitize_html_content()`

## Patterns

### Field-Level Validation
```python
from django import forms
from django.core.exceptions import ValidationError

class RegistrationForm(forms.Form):
    username = forms.CharField(max_length=30, min_length=3)
    email = forms.EmailField()
    password = forms.CharField(widget=forms.PasswordInput)
    password_confirm = forms.CharField(widget=forms.PasswordInput)

    def clean_username(self) -> str:
        username = self.cleaned_data["username"].strip().lower()
        if User.objects.filter(username=username).exists():
            raise ValidationError("This username is already taken.")
        if not username.isalnum():
            raise ValidationError("Username must be alphanumeric.")
        return username

    def clean_email(self) -> str:
        email = self.cleaned_data["email"].strip().lower()
        if User.objects.filter(email=email).exists():
            raise ValidationError("An account with this email already exists.")
        return email
```

### Cross-Field Validation with clean()
```python
    def clean(self) -> dict[str, Any]:
        cleaned = super().clean()
        password = cleaned.get("password")
        password_confirm = cleaned.get("password_confirm")

        if password and password_confirm and password != password_confirm:
            self.add_error("password_confirm", "Passwords do not match.")

        return cleaned
```

### HTML Sanitization in Forms
```python
from apps.core.sanitizers import sanitize_html_content

class TopicForm(forms.ModelForm):
    class Meta:
        model = ForumTopic
        fields = ["title", "content"]

    def clean_content(self) -> str:
        content = self.cleaned_data["content"]
        return sanitize_html_content(content)

    def clean_title(self) -> str:
        title = self.cleaned_data["title"].strip()
        if len(title) < 5:
            raise ValidationError("Title must be at least 5 characters.")
        # Strip HTML from title — titles should be plain text
        import re
        return re.sub(r"<[^>]+>", "", title)
```

### Custom Error Messages
```python
class FirmwareUploadForm(forms.ModelForm):
    class Meta:
        model = Firmware
        fields = ["name", "version", "file"]
        error_messages = {
            "name": {
                "required": "Please provide a firmware name.",
                "max_length": "Name cannot exceed 255 characters.",
            },
            "version": {
                "required": "Version number is required.",
            },
        }

    def clean_file(self) -> Any:
        file = self.cleaned_data.get("file")
        if not file:
            raise ValidationError("Please select a file to upload.")

        MAX_SIZE = 500 * 1024 * 1024  # 500 MB
        if file.size > MAX_SIZE:
            raise ValidationError(
                f"File is too large ({file.size // (1024*1024)} MB). Maximum: 500 MB."
            )
        return file
```

### Template Error Display
```html
<!-- Form-level errors -->
{% include "components/_form_errors.html" with form=form %}

<form method="post">
    {% csrf_token %}

    {% for field in form %}
    <div class="form-group {% if field.errors %}has-error{% endif %}">
        <label for="{{ field.id_for_label }}">{{ field.label }}</label>
        {{ field }}
        {% include "components/_field_error.html" with field=field %}
        {% if field.help_text %}
        <p class="help-text">{{ field.help_text }}</p>
        {% endif %}
    </div>
    {% endfor %}

    <button type="submit">Submit</button>
</form>
```

### HTMX Inline Validation
```python
@require_POST
def validate_username(request: HttpRequest) -> HttpResponse:
    """HTMX endpoint: validate username availability on blur."""
    username = request.POST.get("username", "").strip().lower()
    if len(username) < 3:
        return HttpResponse('<span class="text-red-500">Too short</span>')
    if User.objects.filter(username=username).exists():
        return HttpResponse('<span class="text-red-500">Already taken</span>')
    return HttpResponse('<span class="text-green-500">Available</span>')
```

### Validation Flow

```
1. form.is_valid() called
2. For each field: field.clean() → clean_<fieldname>()
3. After all fields: form.clean()
4. If no errors: form.cleaned_data is populated
5. Errors stored in form.errors dict (field → [messages])
```

## Anti-Patterns
- Not returning the cleaned value from `clean_<fieldname>()` — data is lost
- Raising `ValidationError` in `clean()` without field key — error goes to `__all__`
- Validating in views instead of forms — centralize in form class
- Not sanitizing HTML content from user input — XSS vulnerability
- Inline error HTML — use `{% include "components/_field_error.html" %}`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Form Validation](https://docs.djangoproject.com/en/5.2/ref/forms/validation/)
- `templates/components/_form_errors.html` — form error display component
- `templates/components/_field_error.html` — field error display component
