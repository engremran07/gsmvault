---
name: template-builder
description: "Create Django HTML templates with Tailwind CSS, Alpine.js, HTMX. Use when: building page templates, creating base layouts, component partials, includes, template inheritance, blocks, Django template tags."
---

# Template Builder

You build Django HTML templates for this platform using Tailwind CSS, Alpine.js, and HTMX.

## Rules

1. Every page extends a layout (`layouts/default.html`, `layouts/dashboard.html`, etc.)
2. Every layout extends `base/_base.html`
3. Partials start with underscore: `_card.html`, `_nav.html`
4. HTMX fragments are separate partial templates
5. Use `{% load static %}` at top of templates that reference static files
6. All colors via CSS custom properties: `var(--color-*)` — never hardcoded
7. CSP nonce on inline scripts: `nonce="{{ request.csp_nonce }}"`
8. `{% csrf_token %}` in every `<form method="post">`
9. Use `{% include %}` for reusable components
10. Use `{% block %}` for overridable sections

## Template Hierarchy

```text
base/_base.html → layouts/default.html → pages/home.html
base/_base.html → layouts/dashboard.html → user/dashboard.html
base/_base.html → layouts/auth.html → auth/login.html
base/_base.html → layouts/minimal.html → errors/404.html
```

## Patterns

### Page Template

```html
{% extends "layouts/default.html" %}
{% load static %}

{% block page_header %}
<h1 class="text-3xl font-bold text-[var(--color-text-primary)]">Page Title</h1>
{% endblock %}

{% block page_content %}
<div class="grid grid-cols-1 md:grid-cols-3 gap-6">
  {% for item in items %}
    {% include "components/_card.html" with title=item.name %}
  {% endfor %}
</div>
{% include "components/_pagination.html" %}
{% endblock %}
```

### Component Partial

```html
{# components/_card.html #}
<div class="bg-[var(--color-card)] border border-[var(--color-border)] rounded-[var(--radius-lg)] p-6">
  <h3 class="font-semibold">{{ title }}</h3>
  {% if description %}<p class="text-[var(--color-text-secondary)] text-sm mt-2">{{ description }}</p>{% endif %}
</div>
```

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
