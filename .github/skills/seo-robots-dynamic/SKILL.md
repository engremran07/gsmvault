---
name: seo-robots-dynamic
description: "Dynamic robots.txt with environment awareness. Use when: generating robots.txt from Django view, blocking staging crawlers, configuring crawl rules per environment."
---

# Dynamic robots.txt

## When to Use

- Serving robots.txt from a Django view instead of static file
- Blocking all crawlers on staging/dev environments
- Dynamically including sitemap URL

## Rules

### View Pattern

```python
# apps/seo/views.py
from django.conf import settings
from django.http import HttpResponse

def robots_txt(request):
    """Dynamic robots.txt — blocks crawlers on non-production."""
    site_url = request.build_absolute_uri("/").rstrip("/")

    if not getattr(settings, "IS_PRODUCTION", False):
        # Block everything on staging/dev
        content = "User-agent: *\nDisallow: /\n"
    else:
        lines = [
            "User-agent: *",
            "Allow: /",
            "",
            "# Protected paths",
            "Disallow: /admin/",
            "Disallow: /api/",
            "Disallow: /accounts/",
            "Disallow: /wallet/",
            "Disallow: /search/",
            "",
            f"Sitemap: {site_url}/sitemap-index.xml",
        ]
        # Add custom rules from database
        from apps.seo.models import SEOSettings
        seo_settings = SEOSettings.get_solo()
        if seo_settings.extra_robots_rules:
            lines.append("")
            lines.append(seo_settings.extra_robots_rules)
        content = "\n".join(lines) + "\n"

    return HttpResponse(content, content_type="text/plain")
```

### URL Configuration

```python
# app/urls.py
from apps.seo.views import robots_txt

urlpatterns = [
    path("robots.txt", robots_txt, name="robots_txt"),
    # ...
]
```

### Environment Detection

```python
# app/settings.py
IS_PRODUCTION = False  # Base

# app/settings_production.py
IS_PRODUCTION = True
```

### Standard Disallow Rules

| Path | Reason |
|------|--------|
| `/admin/` | Admin panel |
| `/api/` | API endpoints |
| `/accounts/` | Auth pages |
| `/wallet/` | User financial data |
| `/search/` | Search results (thin content) |
| `/static/` | Optional — crawlers usually ignore |

## Anti-Patterns

- Static `robots.txt` file that allows crawling on staging
- Missing `Sitemap:` directive — always include
- Blocking CSS/JS files — Google needs them for rendering
- Using `robots.txt` template without `text/plain` content type

## Red Flags

- Production robots.txt has `Disallow: /` (blocks entire site)
- Staging robots.txt allows crawling (leaks pre-release content)
- No sitemap URL in robots.txt

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
