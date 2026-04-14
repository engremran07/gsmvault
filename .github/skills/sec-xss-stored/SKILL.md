---
name: sec-xss-stored
description: "Stored XSS prevention: sanitize before save, sanitize on output. Use when: saving user HTML content, rendering stored content, audit of persistence layer."
---

# Stored XSS Prevention

## When to Use

- Saving any user-supplied HTML to the database
- Rendering stored content that may contain HTML
- Auditing models with `TextField` that accept rich content

## Rules

| Step | Action | Where |
|------|--------|-------|
| 1 | Sanitize on input | Service layer `create_*()` / `update_*()` |
| 2 | Store sanitized | Database stores only clean HTML |
| 3 | Render with `|safe` | Template — safe because input was sanitized |

## Patterns

### Service Layer Sanitization
```python
from apps.core.sanitizers import sanitize_html_content

def update_post(post: Post, body: str) -> Post:
    post.body = sanitize_html_content(body)
    post.save(update_fields=["body", "updated_at"])
    return post
```

### Model-Level Validation (Defense in Depth)
```python
from django.db import models
from apps.core.sanitizers import sanitize_html_content

class ForumReply(models.Model):
    content = models.TextField()

    def clean(self) -> None:
        super().clean()
        self.content = sanitize_html_content(self.content)
```

### Template Rendering
```html
{# body was sanitized via nh3 in service layer — safe to render #}
<article class="prose">{{ post.body|safe }}</article>

{# title is plain text — auto-escaped by Django, no |safe needed #}
<h1>{{ post.title }}</h1>
```

### Fields That MUST Be Sanitized

| Model | Field | Sanitizer |
|-------|-------|-----------|
| `Post.body` | Rich HTML | `sanitize_html_content()` |
| `ForumReply.content` | Rich HTML | `sanitize_html_content()` |
| `AdCreative.body` | Ad HTML | `sanitize_ad_code()` |
| `Page.content` | CMS HTML | `sanitize_html_content()` |

## Red Flags

- `TextField` storing user HTML without sanitization in the write path
- `|safe` on a field with no confirmed sanitization
- Sanitizing only on output (not on save) — stale data remains dirty
- Using `bleach` instead of `nh3`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
