---
name: seo-interlinking-injection
description: "Auto-injection of internal links in content. Use when: automatically inserting links into blog/page content, replacing keywords with hyperlinks."
---

# Auto-Injection of Internal Links

## When to Use

- Automatically inserting internal links into blog post content
- Replacing keyword phrases with hyperlinks
- Building a link injection pipeline from `LinkSuggestion` records

## Rules

### Link Injection Service

```python
# apps/seo/services.py
import re
from html import escape

def inject_internal_links(
    html_content: str,
    links: list[dict[str, str]],
    max_links: int = 5,
    max_per_keyword: int = 1,
) -> str:
    """Inject internal links by replacing keyword occurrences in content.
    links: [{'keyword': 'firmware', 'url': '/firmwares/', 'title': 'Browse firmwares'}]
    """
    injected = 0
    for link in links:
        if injected >= max_links:
            break
        keyword = re.escape(link["keyword"])
        url = escape(link["url"])
        title = escape(link.get("title", ""))
        # Only replace in text nodes (not inside existing tags)
        pattern = rf"(?<![<\w/])(?<![\"'])\b({keyword})\b(?![\"'>])"
        replacement = f'<a href="{url}" title="{title}">\\1</a>'
        html_content, count = re.subn(pattern, replacement, html_content, count=max_per_keyword, flags=re.IGNORECASE)
        if count > 0:
            injected += count
    return html_content
```

### Building Link Map from Suggestions

```python
def get_injection_links(page_path: str) -> list[dict[str, str]]:
    """Get approved link suggestions for a page."""
    from apps.seo.models import LinkSuggestion, LinkableEntity
    suggestions = (
        LinkSuggestion.objects
        .filter(source__path=page_path, status="approved")
        .select_related("target")
        .order_by("-score")[:10]
    )
    return [
        {
            "keyword": s.anchor_text or s.target.title,
            "url": s.target.path,
            "title": s.target.title,
        }
        for s in suggestions
        if s.target.path and s.anchor_text
    ]
```

### Safety Constraints

| Rule | Limit |
|------|-------|
| Max links per page | 5 |
| Max links per keyword | 1 (first occurrence only) |
| No injection inside `<a>`, `<code>`, `<pre>` | Skip tag interiors |
| No injection in headings | Skip `<h1>`–`<h6>` |
| Min keyword length | 3 characters |

### Template Filter Approach

```python
# apps/seo/templatetags/seo_tags.py
from django import template
from apps.seo.services import inject_internal_links, get_injection_links

register = template.Library()

@register.filter(is_safe=True)
def autolink(content, page_path):
    """Auto-inject internal links: {{ post.content|autolink:post.get_absolute_url }}"""
    links = get_injection_links(page_path)
    return inject_internal_links(content, links)
```

## Anti-Patterns

- Injecting links inside existing `<a>` tags — creates nested anchors
- No limit on injections per page — clutters content, hurts UX
- Injecting into headings — damages heading hierarchy for SEO
- Replacing in code blocks — corrupts code examples

## Red Flags

- Regex doesn't skip existing anchor tags
- More than 10 injected links per page
- Keywords shorter than 3 characters (matches noise)
- Missing `escape()` on URL/title — XSS risk

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
