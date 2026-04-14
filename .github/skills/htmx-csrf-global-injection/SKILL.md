---
name: htmx-csrf-global-injection
description: "Global CSRF injection via body hx-headers. Use when: configuring CSRF for all HTMX requests site-wide, setting up base template CSRF, preventing 403 on HTMX POST/PUT/DELETE."
---

# HTMX Global CSRF Injection

## When to Use

- Setting up CSRF protection for ALL HTMX requests in the base template
- Fixing 403 Forbidden errors on HTMX POST/PUT/PATCH/DELETE
- Initial project HTMX integration

## Rules

1. Set `hx-headers` on `<body>` — applies to ALL descendant HTMX elements
2. Use Django `{% csrf_token %}` template tag to get the token value
3. Never use per-element `hx-headers` for CSRF — one global declaration
4. This is the canonical pattern for this project — do NOT use meta tag approach unless dynamic page requires it

## Patterns

### Base Template Body Tag

```html
{# templates/base/base.html #}
<body
  hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'
  class="min-h-screen bg-[var(--color-bg-primary)] text-[var(--color-text-primary)]"
>
  {% block content %}{% endblock %}
</body>
```

### How It Works

Every HTMX request from any element inside `<body>` automatically includes:
```
X-CSRFToken: <django-csrf-token-value>
```

Django's `CsrfViewMiddleware` validates this header on mutating requests.

### HTMX Element — No Extra CSRF Needed

```html
{# The CSRF header is inherited from <body> #}
<button hx-post="{% url 'forum:toggle_like' topic.pk %}"
        hx-target="#like-count-{{ topic.pk }}"
        hx-swap="outerHTML">
  Like
</button>
```

## Anti-Patterns

```html
<!-- WRONG — per-element CSRF (redundant, clutters templates) -->
<button hx-post="/api/like/"
        hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>

<!-- WRONG — missing CSRF entirely (403 on POST) -->
<button hx-post="/api/delete/" hx-swap="outerHTML">

<!-- WRONG — using hx-vals for CSRF -->
<button hx-post="/api/" hx-vals='{"csrfmiddlewaretoken": "..."}'>
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| 403 on HTMX POST | Missing CSRF header | Add `hx-headers` to `<body>` |
| Per-element `hx-headers` with CSRF | Redundant, error-prone | Remove — body handles it |
| `@csrf_exempt` on HTMX views | Security hole | Remove decorator, use global header |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
