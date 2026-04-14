---
name: sec-csp-strict-dynamic
description: "strict-dynamic CSP policy for script loading. Use when: configuring CSP for CDN scripts, trusted script chains, dynamic script loading."
---

# CSP strict-dynamic Policy

## When to Use

- Loading scripts from CDNs with fallback chains
- Allowing dynamically-inserted scripts from trusted sources
- Simplifying CSP for complex script dependency trees

## Rules

| Directive | Effect |
|-----------|--------|
| `'strict-dynamic'` | Scripts loaded by trusted scripts inherit trust |
| With nonce | Root scripts must have nonce; children inherit |
| Ignores allowlists | `'strict-dynamic'` overrides host-based allowlists |
| Browser support | Chrome 52+, Firefox 52+, Safari 15.4+ |

## Patterns

### CSP with strict-dynamic
```python
# Middleware CSP header
csp = (
    f"script-src 'nonce-{nonce}' 'strict-dynamic' https:; "
    "style-src 'self' 'unsafe-inline'; "  # Tailwind needs inline styles
    "img-src 'self' data: https:; "
    "font-src 'self'; "
    "object-src 'none'; "
    "base-uri 'self'; "
    "frame-ancestors 'none';"
)
```

### CDN Fallback Chain with strict-dynamic
```html
<!-- Root script has nonce — children loaded by it inherit trust -->
<script nonce="{{ csp_nonce }}" src="https://cdn.jsdelivr.net/npm/alpinejs@3/dist/cdn.min.js"
        defer
        onerror="
            var s = document.createElement('script');
            s.src = 'https://cdnjs.cloudflare.com/ajax/libs/alpinejs/3.14.3/cdn.min.js';
            s.defer = true;
            document.head.appendChild(s);
        "></script>
<!-- The fallback script inherits trust via strict-dynamic -->
```

### Why strict-dynamic Works Here
```text
1. <script nonce="abc123"> → trusted via nonce
2. That script creates new <script> elements → trusted via strict-dynamic
3. CDN fallback chain works without listing every CDN in CSP
4. Third-party scripts loaded by trusted scripts also inherit trust
```

## Red Flags

- Using `'unsafe-inline'` alongside `'strict-dynamic'` (unsafe-inline is ignored)
- Missing nonce on root scripts — strict-dynamic only trusts scripted children
- Relying on host allowlists with strict-dynamic (they're ignored)
- Not including `https:` fallback for browsers without strict-dynamic support

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
