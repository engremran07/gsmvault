---
name: regression-xss-prevention
description: "XSS regression detection skill. Use when: checking sanitization guards, verifying nh3 usage, scanning for removed sanitize_html calls, detecting |safe without sanitization source."
---

# XSS Regression Detection

## When to Use

- After editing any model with user-supplied HTML content
- After editing templates that use `|safe` filter
- After editing `apps/core/sanitizers.py` or `apps/core/utils/sanitize.py`
- After modifying blog, forum, pages, or comments apps

## Guards to Verify

| File | Guard | Critical |
|------|-------|----------|
| `apps/core/sanitizers.py` | `nh3.clean()` in `sanitize_html_content()` | YES |
| `apps/core/utils/sanitize.py` | `nh3.clean()` in `sanitize_html()` | YES |
| `apps/blog/models.py` | `sanitize_html()` in `Post.save()` | YES |
| `apps/forum/services.py` | `sanitize_html_content()` in `render_markdown()` | YES |
| `apps/pages/models.py` | `sanitize_html_content()` in `Page.save()` | YES |

## Procedure

1. Search for `import nh3` in sanitizer files — must be present
2. Search for `sanitize_html` calls in model save methods — must be present
3. Search for `|safe` in templates — each must trace to a sanitized source
4. Search for `bleach` — must NOT be used (replaced by nh3)
5. Verify `nh3` is in `requirements.txt`

## Red Flags

- `|safe` on raw user input without prior sanitization
- `mark_safe()` on user-supplied content
- `sanitize_html` import removed from a model file
- `bleach` imported anywhere (deprecated, replaced by nh3)
- Raw HTML stored without sanitization on save

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
