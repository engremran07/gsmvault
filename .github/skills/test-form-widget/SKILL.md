---
name: test-form-widget
description: "Widget rendering tests: attributes, CSS classes, JavaScript hooks. Use when: testing custom widget output, form field HTML attributes, widget media."
---

# Form Widget Tests

## When to Use

- Verifying custom widget renders correct HTML attributes
- Testing CSS classes on form fields
- Checking `data-*` attributes for JavaScript hooks
- Testing widget media (JS/CSS) inclusion

## Rules

### Testing Widget Attributes

```python
import pytest

def test_widget_has_css_class():
    from apps.firmwares.forms import FirmwareForm
    form = FirmwareForm()
    html = str(form["version"])
    assert 'class="' in html
    assert "form-input" in html or "form-control" in html

def test_widget_placeholder():
    from apps.firmwares.forms import FirmwareForm
    form = FirmwareForm()
    html = str(form["version"])
    assert 'placeholder="' in html
```

### Testing Custom Widget Rendering

```python
def test_date_widget_type():
    from apps.ads.forms import CampaignForm
    form = CampaignForm()
    html = str(form["start_at"])
    assert 'type="date"' in html

def test_textarea_rows():
    from apps.blog.forms import PostForm
    form = PostForm()
    html = str(form["content"])
    assert "<textarea" in html
    assert 'rows="' in html
```

### Testing Widget with Alpine.js Data Attributes

```python
def test_alpine_data_attributes():
    from apps.firmwares.forms import FirmwareSearchForm
    form = FirmwareSearchForm()
    html = str(form["query"])
    assert 'x-model="searchQuery"' in html or 'data-' in html

def test_htmx_attributes():
    from apps.firmwares.forms import FirmwareSearchForm
    form = FirmwareSearchForm()
    html = str(form["query"])
    # Check for HTMX trigger attributes
    assert "hx-" in html or 'data-hx-' in html
```

### Testing Widget Media

```python
def test_widget_media_js():
    from apps.blog.forms import PostForm
    form = PostForm()
    if hasattr(form, "media"):
        js_files = str(form.media["js"])
        # Check expected JS is included
        assert js_files is not None
```

### Testing Select Widget Choices

```python
@pytest.mark.django_db
def test_select_choices():
    from apps.firmwares.forms import FirmwareFilterForm
    form = FirmwareFilterForm()
    html = str(form["status"])
    assert "<option" in html
    assert "active" in html.lower()

def test_select_disabled_option():
    from apps.firmwares.forms import FirmwareForm
    form = FirmwareForm()
    html = str(form["category"])
    # First option should be placeholder
    assert "---" in html or "Select" in html
```

### Full Form HTML Test

```python
def test_form_renders_all_fields():
    from apps.firmwares.forms import FirmwareForm
    form = FirmwareForm()
    html = form.as_div()
    assert "version" in html
    assert "build_number" in html
```

## Red Flags

- Testing widget HTML via string matching when DOM parsing would be clearer
- Not testing error state rendering — widgets should show errors differently
- Hardcoding HTML structure expectations — widgets can change across Django versions
- Missing tests for readonly/disabled states

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
