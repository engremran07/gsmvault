---
name: sec-xss-nh3
description: "nh3 sanitizer usage: sanitize_html_content(), sanitize_ad_code(), allowed tags. Use when: configuring HTML sanitization, adding new sanitizer functions."
---

# nh3 Sanitizer Usage

## When to Use

- Sanitizing user-supplied HTML content
- Configuring allowed HTML tags/attributes
- Adding new sanitizer functions for specific contexts

## Rules

| Function | Use Case | Allowed Tags |
|----------|----------|--------------|
| `sanitize_html_content()` | Blog, forum, page content | `p, a, strong, em, ul, ol, li, h2-h6, blockquote, code, pre, img, br, hr` |
| `sanitize_ad_code()` | Ad creative HTML | `div, span, a, img, script` (ad network scripts) |

**CRITICAL**: Never use `bleach` — it is deprecated. `nh3` is the Rust-based replacement.

## Patterns

### Basic Sanitization
```python
import nh3

def sanitize_html_content(html: str) -> str:
    """Sanitize user HTML content, keeping safe formatting tags."""
    return nh3.clean(
        html,
        tags={"p", "a", "strong", "em", "ul", "ol", "li", "h2", "h3",
              "h4", "h5", "h6", "blockquote", "code", "pre", "img", "br", "hr"},
        attributes={
            "a": {"href", "title", "rel"},
            "img": {"src", "alt", "width", "height"},
        },
        url_schemes={"http", "https", "mailto"},
        link_rel="noopener noreferrer",
    )
```

### Ad Code Sanitization
```python
def sanitize_ad_code(html: str) -> str:
    """Sanitize ad network HTML — allows script tags from known networks."""
    return nh3.clean(
        html,
        tags={"div", "span", "a", "img", "script", "ins"},
        attributes={
            "div": {"class", "id", "style", "data-ad-slot"},
            "script": {"src", "async", "data-ad-client"},
            "ins": {"class", "data-ad-client", "data-ad-slot", "style"},
        },
    )
```

### Usage in Services
```python
from apps.core.sanitizers import sanitize_html_content

def create_forum_reply(topic_id: int, content: str, user: User) -> ForumReply:
    return ForumReply.objects.create(
        topic_id=topic_id,
        content=sanitize_html_content(content),
        author=user,
    )
```

## Red Flags

- `import bleach` anywhere — must be `import nh3`
- Calling `nh3.clean()` without explicit `tags` (defaults may be too permissive)
- Allowing `javascript:` in `url_schemes`
- Missing `link_rel="noopener noreferrer"` on links
- Not sanitizing ad code separately from content

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
