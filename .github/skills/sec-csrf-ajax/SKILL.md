---
name: sec-csrf-ajax
description: "AJAX CSRF: getCookie('csrftoken'), X-CSRFToken header. Use when: making fetch/XHR requests from JavaScript, configuring API calls."
---

# AJAX CSRF Token Handling

## When to Use

- Making `fetch()` or `XMLHttpRequest` calls from JavaScript
- Configuring CSRF for non-HTMX AJAX requests
- Building Alpine.js components that POST data

## Patterns

### getCookie Helper
```javascript
// static/js/src/csrf.js
function getCookie(name) {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) return parts.pop().split(';').shift();
    return null;
}
```

### Fetch with CSRF
```javascript
async function postData(url, data) {
    const response = await fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRFToken': getCookie('csrftoken'),
        },
        credentials: 'same-origin',
        body: JSON.stringify(data),
    });
    return response.json();
}
```

### Alpine.js Component with CSRF
```html
<div x-data="{ loading: false }">
    <button @click="
        loading = true;
        fetch('{% url 'api:toggle' %}', {
            method: 'POST',
            headers: {
                'X-CSRFToken': getCookie('csrftoken'),
                'Content-Type': 'application/json',
            },
            credentials: 'same-origin',
            body: JSON.stringify({ id: {{ item.pk }} }),
        })
        .then(r => r.json())
        .then(data => { loading = false; })
    " x-text="loading ? 'Saving...' : 'Toggle'"></button>
</div>
```

### Meta Tag Fallback
```html
<meta name="csrf-token" content="{{ csrf_token }}">
<script nonce="{{ csp_nonce }}">
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
</script>
```

## Red Flags

- Missing `credentials: 'same-origin'` on fetch — cookie won't be sent
- Hardcoded CSRF token in JavaScript files
- Missing `X-CSRFToken` header on POST/PUT/PATCH/DELETE
- Using `GET` for state-changing AJAX operations

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
