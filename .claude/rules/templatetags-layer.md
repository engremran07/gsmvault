---
paths: ["apps/*/templatetags/*.py"]
---

# Template Tags Layer Rules

Custom template tags and filters extend Django's template language. They must be simple, fast, and side-effect-free.

## File Structure

- Place tag libraries in `apps/<appname>/templatetags/<taglib>.py`.
- The `templatetags/` directory MUST contain an `__init__.py` file.
- Name the tag library after the app or feature: `forum_tags.py`, `seo_helpers.py`.
- Load in templates with: `{% load taglib %}`.

## Registration

- ALWAYS use `template.Library()` to register tags and filters:
  ```python
  from django import template
  register = template.Library()
  ```
- Use `@register.filter` for value transformations: `{{ value|my_filter }}`.
- Use `@register.simple_tag` for tags that output a value: `{% my_tag arg1 arg2 %}`.
- Use `@register.inclusion_tag("path/to/template.html")` for tags that render sub-templates.

## Complexity Rules

- Template tags MUST be simple — complex logic belongs in services, called from views.
- NEVER do database queries in template tags — pass data from views via context.
- NEVER call external APIs or services from template tags.
- NEVER modify model state in template tags — they are read-only presenters.
- Keep tag functions under 15 lines — if longer, the logic should move to a view or service.

## Type Safety

- ALWAYS type-hint tag function parameters and return types.
- Use `str` return type for filters that transform text.
- Use `dict` return type for `inclusion_tag` functions.
- Handle `None` inputs gracefully — return empty string or safe default, never raise.

## Filters

- Filters MUST be pure functions — same input always produces same output.
- Mark filters that output HTML as safe with `@register.filter(is_safe=True)` — only if output is properly sanitized.
- NEVER mark a filter as `is_safe=True` if it includes user-supplied content without sanitization.
- Common patterns: date formatting, truncation, currency display, status badge rendering.

## Testing

- Test tags/filters as regular Python functions — import and call directly.
- Test `inclusion_tag` by rendering the template string and asserting output HTML.
- Test edge cases: None input, empty string, invalid types.
