---
name: htmx-vary-header-cache
description: "Vary header for HTMX vs full-page caching. Use when: CDN/browser caching with dual-mode views, preventing cached fragment served as full page, cache key separation."
---

# HTMX Vary Header for Cache Separation

## When to Use

- Views that return full pages for normal requests and fragments for HTMX
- Preventing CDN/browser cache from serving a fragment as a full page (or vice versa)
- Any dual-mode view with caching enabled

## Rules

1. Add `Vary: HX-Request` header on dual-mode responses
2. Set the Vary header in the view OR use middleware for all responses
3. Required when using `@cache_page`, CDN caching, or browser cache
4. Without Vary, a cached HTMX fragment may be served as a full page

## Patterns

### Per-View Vary Header

```python
def firmware_list(request):
    firmwares = Firmware.objects.filter(is_active=True)
    template = "firmwares/list.html"

    if request.headers.get("HX-Request"):
        template = "firmwares/fragments/list.html"

    response = render(request, template, {"firmwares": firmwares})
    response["Vary"] = "HX-Request"
    return response
```

### Middleware for Automatic Vary Header

```python
# app/middleware/htmx_vary.py

class HtmxVaryMiddleware:
    """Add Vary: HX-Request to all responses for proper caching."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        from django.utils.cache import patch_vary_headers
        patch_vary_headers(response, ["HX-Request"])
        return response
```

### With Django cache_page

```python
from django.views.decorators.cache import cache_page
from django.views.decorators.vary import vary_on_headers

@cache_page(60 * 15)
@vary_on_headers("HX-Request")
def search_results(request):
    query = request.GET.get("q", "")
    results = Firmware.objects.filter(name__icontains=query)

    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/search.html",
                      {"results": results})
    return render(request, "firmwares/search.html",
                  {"results": results, "query": query})
```

### CDN Configuration Note

```text
# If using Cloudflare or similar CDN:
# Ensure the CDN respects the Vary header.
# Some CDNs need explicit configuration to vary on custom headers.
# Cloudflare: Page Rule → Cache Level: Standard (respects Vary)
```

## Anti-Patterns

```python
# WRONG — cached dual-mode view without Vary header
@cache_page(60 * 15)
def firmware_list(request):
    if request.headers.get("HX-Request"):
        return render(request, "fragments/list.html")  # cached as full page!
    return render(request, "list.html")
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| Dual-mode view with `@cache_page` but no Vary | Wrong response served from cache | Add `@vary_on_headers("HX-Request")` |
| Fragment HTML served as full page | User sees bare HTML without layout | Add `Vary: HX-Request` |
| CDN ignoring Vary header | Same issue at CDN level | Configure CDN to respect Vary |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
