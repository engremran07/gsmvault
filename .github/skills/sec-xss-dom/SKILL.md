---
name: sec-xss-dom
description: "DOM-based XSS prevention in Alpine.js/HTMX templates. Use when: writing Alpine.js x-html, HTMX swap targets, client-side rendering."
---

# DOM-Based XSS Prevention

## When to Use

- Writing Alpine.js components that render HTML (`x-html`)
- Creating HTMX swap targets that inject server HTML
- Using `innerHTML` or `document.write` anywhere

## Rules

| Vector | Guard | Fix |
|--------|-------|-----|
| `x-html` | Never bind user input directly | Sanitize server-side, send safe HTML |
| `x-text` | Safe by default | Prefer `x-text` over `x-html` always |
| `innerHTML` | Forbidden | Use `textContent` or Alpine `x-text` |
| URL params | Never inject into DOM | Validate/encode before display |
| HTMX swaps | Server sanitizes response | All HTMX fragments return sanitized HTML |

## Patterns

### Safe Alpine.js Text Binding
```html
<!-- SAFE: x-text auto-escapes -->
<span x-text="userName"></span>

<!-- UNSAFE: x-html with unvalidated data -->
<div x-html="userBio"></div>  <!-- FORBIDDEN unless server-sanitized -->
```

### Safe HTMX Fragment
```html
<!-- Server returns pre-sanitized HTML -->
<div hx-get="/api/comments/" hx-target="#comments" hx-swap="innerHTML">
    Load Comments
</div>
<!-- The view MUST sanitize before rendering the fragment -->
```

### Safe URL Parameter Display
```javascript
// FORBIDDEN — direct DOM injection
document.getElementById('search').innerHTML = new URLSearchParams(location.search).get('q');

// SAFE — use textContent
document.getElementById('search').textContent = new URLSearchParams(location.search).get('q');
```

### Alpine.js Store — Never Trust Client Data
```html
<div x-data="{ query: '' }">
    <!-- SAFE: x-text for display -->
    <p>Searching for: <span x-text="query"></span></p>
    <!-- FORBIDDEN: x-html with user input -->
    <p x-html="query"></p>
</div>
```

## Red Flags

- `x-html` bound to any user-controlled variable
- `innerHTML` assignment in any `.js` file
- `document.write()` anywhere in codebase
- URL query parameters rendered without encoding
- HTMX fragments returning unsanitized user content

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
