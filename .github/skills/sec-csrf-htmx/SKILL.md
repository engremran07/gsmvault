---
name: sec-csrf-htmx
description: "HTMX CSRF: global hx-headers on body, meta tag pattern. Use when: configuring HTMX CSRF globally, debugging HTMX 403 errors."
---

# HTMX CSRF Configuration

## When to Use

- Setting up HTMX in a Django project
- Debugging 403 Forbidden on HTMX requests
- Ensuring all HTMX requests include CSRF token

## Rules

| Rule | Implementation |
|------|----------------|
| Global injection | `hx-headers` on `<body>` — covers ALL HTMX requests |
| Per-form NOT needed | Global header handles CSRF for all HTMX verbs |
| Meta tag source | `<meta name="csrf-token">` in `<head>` |

## Patterns

### Global CSRF Header on Body (Canonical Pattern)
```html
<!-- templates/base/base.html -->
<body hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>
    {% block content %}{% endblock %}
</body>
```

This single line ensures every HTMX request (GET, POST, PUT, DELETE) includes the CSRF token.

### Alternative: Meta Tag + JS
```html
<!-- In <head> -->
<meta name="csrf-token" content="{{ csrf_token }}">

<!-- Before closing </body> -->
<script nonce="{{ csp_nonce }}">
    document.body.addEventListener('htmx:configRequest', function(event) {
        event.detail.headers['X-CSRFToken'] =
            document.querySelector('meta[name="csrf-token"]').content;
    });
</script>
```

### HTMX Fragment — No Extra CSRF Needed
```html
<!-- fragments/comment_form.html -->
<!-- No {% csrf_token %} needed — global hx-headers handles it -->
<form hx-post="{% url 'comments:create' %}" hx-target="#comments">
    <textarea name="body" required></textarea>
    <button type="submit">Post</button>
</form>
```

## Red Flags

- HTMX forms with `{% csrf_token %}` but missing `hx-headers` on body (redundant but harmless)
- Missing `hx-headers` on `<body>` tag — all HTMX POST requests will 403
- Per-request CSRF injection via JS instead of global body header
- `hx-headers` with hardcoded token (must use `{{ csrf_token }}` template tag)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
