---
name: htmx-form-inline-errors
description: "Inline form error display with HTMX. Use when: showing field-level validation errors next to form fields, real-time field validation, form re-rendering with errors."
---

# HTMX Inline Form Error Display

## When to Use

- Showing validation errors next to each form field after submission
- Real-time single-field validation (validate on blur)
- Re-rendering form with error highlights via HTMX

## Rules

1. Use `{% include "components/_form_field.html" %}` for consistent field rendering
2. Use `{% include "components/_field_error.html" %}` for error messages
3. Return the full form as a 422 response so errors render inline
4. For per-field validation, use separate endpoints that validate one field

## Patterns

### Form Field with Inline Errors

```html
{# templates/components/_form_field.html already handles this #}
<div class="mb-4">
  <label for="{{ field.id_for_label }}" class="block text-sm font-medium mb-1">
    {{ field.label }}
  </label>
  {{ field }}
  {% if field.errors %}
  {% for error in field.errors %}
  <p class="text-sm text-[var(--color-status-error)] mt-1">{{ error }}</p>
  {% endfor %}
  {% endif %}
</div>
```

### HTMX Form Submission with Error Swap

```html
<form id="register-form"
      hx-post="{% url 'users:register' %}"
      hx-target="#register-form"
      hx-swap="outerHTML">
  {% include "components/_form_field.html" with field=form.username %}
  {% include "components/_form_field.html" with field=form.email %}
  {% include "components/_form_field.html" with field=form.password1 %}
  <button type="submit"
          hx-indicator="#submit-spinner"
          hx-disabled-elt="this">
    Register
  </button>
  <span id="submit-spinner" class="htmx-indicator">
    <i data-lucide="loader-2" class="w-4 h-4 animate-spin"></i>
  </span>
</form>
```

### Per-Field Blur Validation

```html
<input type="text" name="username" id="id_username"
       hx-post="{% url 'users:validate_field' %}"
       hx-trigger="blur changed"
       hx-target="#username-errors"
       hx-vals='{"field": "username"}'
       hx-swap="innerHTML">
<div id="username-errors"></div>
```

```python
# views.py
def validate_field(request):
    field = request.POST.get("field")
    form = RegistrationForm(request.POST)
    form.is_valid()  # trigger validation
    errors = form.errors.get(field, [])
    if errors:
        html = "".join(f'<p class="text-sm text-red-500">{e}</p>' for e in errors)
        return HttpResponse(html, status=422)
    return HttpResponse('<p class="text-sm text-green-500">✓</p>')
```

## Anti-Patterns

```html
<!-- WRONG — alert on validation error -->
<form hx-post="/submit/" hx-on::afterRequest="if(event.detail.failed) alert('Fix errors')">

<!-- WRONG — clearing errors on re-submission (they should be replaced by new response) -->
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No error display after form submit | Errors swallowed silently | Return 422 with re-rendered form |
| Custom error HTML per form | Inconsistent error display | Use `_form_field.html` component |
| Errors clear but form doesn't resubmit | Stale form state | Use `hx-swap="outerHTML"` on form |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
