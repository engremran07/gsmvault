---
name: htmx-form-validation-422
description: "422 response handling for validation errors. Use when: returning server-side validation errors from HTMX form submissions, swapping error content on 422."
---

# HTMX 422 Validation Error Handling

## When to Use

- Django form validation fails and you need to show errors inline
- API returns 422 Unprocessable Entity with error details
- Re-rendering the form with error messages via HTMX

## Rules

1. Return HTTP 422 from Django views on validation failure
2. Configure HTMX to swap content on 422: `htmx.config.responseHandling`
3. Return the re-rendered form with errors as the 422 response body
4. Never return JSON for HTMX validation errors — return HTML

## Patterns

### Configure HTMX to Swap on 422

```html
{# templates/base/base.html #}
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('DOMContentLoaded', function() {
  // Allow HTMX to swap content on 422 (validation errors)
  htmx.config.responseHandling = [
    {code: "204", swap: false},
    {code: "[23]..", swap: true},
    {code: "422", swap: true, error: false},
    {code: "[45]..", swap: false, error: true},
  ];
});
</script>
```

### Django View Returning 422

```python
from django.http import HttpResponse

def create_topic(request):
    if request.method == "POST":
        form = TopicForm(request.POST)
        if form.is_valid():
            topic = form.save(commit=False)
            topic.author = request.user
            topic.save()
            return HttpResponse(
                headers={"HX-Redirect": topic.get_absolute_url()}
            )
        # Validation failed — return form with errors as 422
        return render(
            request, "forum/fragments/topic_form.html",
            {"form": form}, status=422,
        )
    form = TopicForm()
    return render(request, "forum/fragments/topic_form.html", {"form": form})
```

### Form Template with Error Display

```html
{# templates/forum/fragments/topic_form.html #}
<form hx-post="{% url 'forum:create_topic' %}"
      hx-target="this" hx-swap="outerHTML">
  {% if form.non_field_errors %}
  {% include "components/_form_errors.html" with errors=form.non_field_errors %}
  {% endif %}
  {% include "components/_form_field.html" with field=form.title %}
  {% include "components/_form_field.html" with field=form.body %}
  <button type="submit">Create Topic</button>
</form>
```

## Anti-Patterns

```python
# WRONG — returning 200 with error form (HTMX can't distinguish success/error)
if not form.is_valid():
    return render(request, "form.html", {"form": form}, status=200)

# WRONG — returning JSON errors for HTMX
return JsonResponse({"errors": form.errors}, status=422)
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| Form errors return 200 | Can't distinguish success from error | Return 422 on validation failure |
| No `responseHandling` config | 422 not swapped, errors not shown | Configure responseHandling |
| JSON error response for HTMX | HTMX can't render JSON | Return HTML fragment |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
