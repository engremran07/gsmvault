---
name: test-template-tag
description: "Custom template tag tests: tag rendering, context manipulation. Use when: testing custom template tags and filters, inclusion tags, assignment tags."
---

# Custom Template Tag Tests

## When to Use

- Testing `@register.simple_tag` output
- Testing `@register.inclusion_tag` rendering
- Testing `@register.filter` transformations
- Verifying template tag library loading

## Rules

### Testing Simple Tags

```python
import pytest
from django.template import Template, Context

def test_simple_tag_output():
    template = Template('{% load my_tags %}{% my_tag "hello" %}')
    context = Context({})
    result = template.render(context)
    assert "hello" in result
```

### Testing Filters

```python
def test_custom_filter():
    template = Template('{% load my_filters %}{{ value|truncate_words:5 }}')
    context = Context({"value": "This is a very long sentence with many words"})
    result = template.render(context)
    assert len(result.split()) <= 6  # 5 words + ellipsis

def test_filter_with_none():
    template = Template('{% load my_filters %}{{ value|default_if_none:"N/A" }}')
    context = Context({"value": None})
    result = template.render(context)
    assert "N/A" in result
```

### Testing Inclusion Tags

```python
@pytest.mark.django_db
def test_inclusion_tag_renders():
    template = Template('{% load admin_tags %}{% admin_sidebar request %}')
    from django.test import RequestFactory
    factory = RequestFactory()
    request = factory.get("/")
    from tests.factories import UserFactory
    request.user = UserFactory(is_staff=True)
    context = Context({"request": request})
    result = template.render(context)
    assert len(result) > 0
```

### Testing Tag with Context

```python
def test_tag_modifies_context():
    template = Template(
        '{% load seo_tags %}{% get_meta_title as meta_title %}{{ meta_title }}'
    )
    context = Context({"page_title": "Test Page"})
    result = template.render(context)
    assert "Test" in result or len(result) > 0
```

### Testing Tag Library Loads

```python
def test_tag_library_exists():
    from django.template import engines
    engine = engines["django"]
    try:
        engine.engine.template_libraries["my_tags"]
    except KeyError:
        pytest.fail("Template library 'my_tags' not found")

def test_all_template_libraries_load():
    """Verify all registered template tag libraries can be imported."""
    from django.template import Template
    libraries = ["seo_tags", "consent_tags", "forum_tags"]
    for lib in libraries:
        try:
            Template(f'{{% load {lib} %}}').render(Context({}))
        except Exception as e:
            if "is not a registered tag library" in str(e):
                pytest.fail(f"Library {lib} failed to load")
```

### Testing Filter Edge Cases

```python
@pytest.mark.parametrize("input_val,expected", [
    ("", ""),
    (None, ""),
    ("<script>alert('xss')</script>", ""),  # Should be sanitized
    ("Normal text", "Normal text"),
])
def test_sanitize_filter(input_val, expected):
    from apps.core.templatetags.core_filters import sanitize
    result = sanitize(input_val)
    assert "<script>" not in result
```

## Red Flags

- Not testing with empty/None input — filters must handle edge cases
- Missing XSS test for filters that output HTML
- Testing tags only with `render()` call — also test the underlying function
- Not verifying tag library registration — `{% load %}` failures are silent

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
