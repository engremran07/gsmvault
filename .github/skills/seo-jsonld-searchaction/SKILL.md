---
name: seo-jsonld-searchaction
description: "JSON-LD SearchAction for sitelinks search. Use when: configuring sitelinks search box, adding search functionality to WebSite schema, URL template patterns."
---

# JSON-LD SearchAction

## When to Use

- Enabling Google sitelinks search box
- Configuring search URL template for structured data
- Multiple search targets (site search + firmware search)

## Rules

### Standalone SearchAction Pattern

```python
# apps/seo/services.py
def build_search_action(
    site_url: str,
    search_path: str = "/search/",
    query_param: str = "q",
) -> dict:
    """Build SearchAction for use inside WebSite schema."""
    return {
        "@type": "SearchAction",
        "target": {
            "@type": "EntryPoint",
            "urlTemplate": f"{site_url}{search_path}?{query_param}={{search_term_string}}",
        },
        "query-input": "required name=search_term_string",
    }
```

### Multiple Search Targets

```python
def build_website_with_searches(site_url: str) -> dict:
    """WebSite schema with multiple search actions."""
    return {
        "@context": "https://schema.org",
        "@type": "WebSite",
        "name": "GSMFWs",
        "url": site_url,
        "potentialAction": [
            build_search_action(site_url, "/search/", "q"),
            build_search_action(site_url, "/firmwares/search/", "query"),
        ],
    }
```

### URL Template Requirements

| Rule | Example |
|------|---------|
| Template variable in braces | `{search_term_string}` |
| Must match query-input name | `name=search_term_string` |
| URL must be valid when filled | `/search/?q=test` returns 200 |
| HTTPS preferred | `https://example.com/search/` |

### Validation

```python
def validate_search_action(schema: dict) -> list[str]:
    """Validate SearchAction schema structure."""
    errors = []
    action = schema.get("potentialAction")
    if not action:
        errors.append("Missing potentialAction")
        return errors
    actions = action if isinstance(action, list) else [action]
    for a in actions:
        template = a.get("target", {})
        if isinstance(template, dict):
            url = template.get("urlTemplate", "")
        else:
            url = template
        if "{search_term_string}" not in url:
            errors.append(f"URL template missing placeholder: {url}")
        qi = a.get("query-input", "")
        if "search_term_string" not in qi:
            errors.append(f"query-input missing variable name: {qi}")
    return errors
```

## Anti-Patterns

- SearchAction without a working search endpoint — the URL must resolve
- Placeholder name mismatch between `urlTemplate` and `query-input`
- Using GET parameters that the search view doesn't accept

## Red Flags

- `urlTemplate` contains literal `{` without template variable
- No `required` prefix in `query-input`
- Search endpoint returns 404 or redirects to homepage

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
