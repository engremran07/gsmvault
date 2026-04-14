---
name: sec-xss-prevention
description: "XSS prevention overview: nh3.clean, auto-escaping, |safe audit. Use when: reviewing XSS posture, auditing templates for |safe usage, checking sanitization."
---

# XSS Prevention Overview

## When to Use

- Auditing templates for unescaped output (`|safe`, `{% autoescape off %}`)
- Reviewing user-generated content rendering
- Adding new fields that accept HTML input

## Rules

| Layer | Guard | Implementation |
|-------|-------|----------------|
| Input | Sanitize before save | `sanitize_html_content(user_input)` in service layer |
| Output | Django auto-escaping | Default ON — never disable without sanitized source |
| Template | `|safe` audit | Only on pre-sanitized content from `nh3.clean()` |
| API | DRF serializer | Validate/strip HTML in serializer `validate_*` methods |

## Procedure

1. **Never use `bleach`** — it is deprecated. Use `nh3` exclusively.
2. Import from `apps.core.sanitizers`:
   ```python
   from apps.core.sanitizers import sanitize_html_content, sanitize_ad_code
   ```
3. Sanitize in the service layer before saving:
   ```python
   def create_post(title: str, body: str, user: User) -> Post:
       return Post.objects.create(
           title=title,
           body=sanitize_html_content(body),
           author=user,
       )
   ```
4. In templates, only use `|safe` on fields known to be sanitized:
   ```html
   {# SAFE — body was sanitized via nh3 before save #}
   <div class="prose">{{ post.body|safe }}</div>

   {# UNSAFE — never do this with raw user input #}
   <div>{{ user_comment|safe }}</div>  {# FORBIDDEN #}
   ```

## Red Flags

- `|safe` on any field without confirmed nh3 sanitization source
- `{% autoescape off %}` blocks in any template
- `mark_safe()` on user-supplied data
- Missing `sanitize_html_content()` call in service layer for HTML fields
- Using `bleach` anywhere — it is replaced by `nh3`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `apps/core/sanitizers.py` — canonical sanitization functions
- `.claude/rules/xss-prevention.md` — XSS rule details
