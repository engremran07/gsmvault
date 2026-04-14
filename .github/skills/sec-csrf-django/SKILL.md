---
name: sec-csrf-django
description: "Django CSRF framework: {% csrf_token %}, middleware, trusted origins. Use when: adding forms, configuring CSRF, debugging 403 Forbidden."
---

# Django CSRF Framework

## When to Use

- Creating any HTML form with POST/PUT/PATCH/DELETE
- Configuring CSRF middleware settings
- Debugging 403 Forbidden on form submissions

## Rules

| Rule | Implementation |
|------|----------------|
| Every `<form method="POST">` | Must include `{% csrf_token %}` |
| Middleware | `CsrfViewMiddleware` always in `MIDDLEWARE` — never remove |
| Trusted origins | `CSRF_TRUSTED_ORIGINS` in settings for cross-origin |
| `@csrf_exempt` | FORBIDDEN on any view handling user data |

## Patterns

### Standard Form
```html
<form method="post" action="{% url 'blog:create' %}">
    {% csrf_token %}
    {{ form.as_div }}
    <button type="submit">Save</button>
</form>
```

### Settings Configuration
```python
# settings.py
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",  # NEVER remove
    # ...
]

CSRF_TRUSTED_ORIGINS = [
    "https://yourdomain.com",
    "https://www.yourdomain.com",
]
CSRF_COOKIE_SECURE = True        # HTTPS only
CSRF_COOKIE_HTTPONLY = False      # Must be False for JS access
CSRF_COOKIE_SAMESITE = "Lax"     # Default Lax is secure
```

### View — Never Exempt
```python
# FORBIDDEN:
@csrf_exempt  # NEVER do this
def my_view(request):
    ...

# CORRECT — CSRF is enforced by middleware automatically
def my_view(request: HttpRequest) -> HttpResponse:
    if request.method == "POST":
        form = MyForm(request.POST)
        if form.is_valid():
            form.save()
    ...
```

## Red Flags

- `@csrf_exempt` on any view handling user data
- Missing `{% csrf_token %}` in POST forms
- `CsrfViewMiddleware` removed from `MIDDLEWARE`
- `CSRF_COOKIE_SECURE = False` in production
- Forms using `method="GET"` for state-changing operations

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
