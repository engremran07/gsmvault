---
name: sec-xss-reflected
description: "Reflected XSS prevention: URL parameter sanitization. Use when: displaying search queries, rendering URL params in templates, GET parameter echo."
---

# Reflected XSS Prevention

## When to Use

- Displaying search query terms back to the user
- Rendering any GET/POST parameter in a template
- Building URLs with user-supplied data

## Rules

| Vector | Guard | Implementation |
|--------|-------|----------------|
| Search query echo | Django auto-escaping | `{{ query }}` (no `|safe`) |
| URL parameter display | Template auto-escape | Never `|safe` on request params |
| Error messages with input | Framework escaping | Use Django messages framework |
| Redirect targets | Allowlist validation | Never redirect to user-supplied URLs |

## Patterns

### Safe Search Query Display
```python
# views.py
def search(request: HttpRequest) -> HttpResponse:
    query = request.GET.get("q", "")
    results = Firmware.objects.filter(name__icontains=query)[:20]
    return render(request, "firmwares/search.html", {
        "query": query,  # Django auto-escapes in template
        "results": results,
    })
```

```html
<!-- Template: auto-escaping prevents XSS -->
<p>Results for: <strong>{{ query }}</strong></p>
<!-- NEVER: <p>Results for: {{ query|safe }}</p> -->
```

### Safe Redirect
```python
from django.utils.http import url_has_allowed_host_and_scheme

def login_redirect(request: HttpRequest) -> HttpResponse:
    next_url = request.GET.get("next", "/")
    if not url_has_allowed_host_and_scheme(next_url, allowed_hosts={request.get_host()}):
        next_url = "/"
    return redirect(next_url)
```

### HTMX Search Fragment
```python
def search_fragment(request: HttpRequest) -> HttpResponse:
    query = request.GET.get("q", "")
    # Never use query in raw HTML — template auto-escapes
    results = Firmware.objects.filter(name__icontains=query)[:10]
    return render(request, "firmwares/fragments/search_results.html", {
        "results": results,
        "query": query,
    })
```

## Red Flags

- `|safe` on any `request.GET` / `request.POST` value
- `mark_safe(request.GET.get(...))` anywhere
- Open redirect: `redirect(request.GET.get("next"))` without validation
- URL parameters interpolated into JavaScript strings

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
