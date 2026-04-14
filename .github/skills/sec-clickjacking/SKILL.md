---
name: sec-clickjacking
description: "Clickjacking prevention: X-Frame-Options, frame-ancestors CSP. Use when: preventing iframe embedding, configuring frame policy."
---

# Clickjacking Prevention

## When to Use

- Preventing the site from being embedded in iframes
- Configuring X-Frame-Options header
- Setting CSP frame-ancestors directive

## Rules

| Header | Value | Purpose |
|--------|-------|---------|
| `X-Frame-Options` | `DENY` | Block all framing |
| `X-Frame-Options` | `SAMEORIGIN` | Allow same-origin framing only |
| CSP `frame-ancestors` | `'none'` | Modern replacement for X-Frame-Options |
| CSP `frame-ancestors` | `'self'` | Same-origin framing only |

## Patterns

### Django Configuration
```python
# settings.py
X_FRAME_OPTIONS = "DENY"  # No iframe embedding anywhere
```

### CSP frame-ancestors (Stronger)
```python
# CSP middleware or django-csp
CSP_FRAME_ANCESTORS = ["'none'"]  # Equivalent to X-Frame-Options: DENY

# Or allow same-origin only
CSP_FRAME_ANCESTORS = ["'self'"]
```

### Per-View Override (Rare)
```python
from django.views.decorators.clickjacking import xframe_options_sameorigin

@xframe_options_sameorigin
def embeddable_widget(request):
    """Allow this view to be framed by same-origin pages."""
    return render(request, "widgets/embed.html")
```

### Exemption for Specific Views
```python
from django.views.decorators.clickjacking import xframe_options_exempt

@xframe_options_exempt
def oembed_endpoint(request):
    """OEmbed endpoints must be frameable."""
    return render(request, "oembed/response.html")
```

### Full CSP Header (in middleware)
```python
class CSPMiddleware:
    def __call__(self, request):
        response = self.get_response(request)
        response["Content-Security-Policy"] = (
            "frame-ancestors 'none'; "
            "default-src 'self'; "
            f"script-src 'nonce-{request.csp_nonce}' 'strict-dynamic'; "
        )
        return response
```

### Testing
```python
def test_clickjacking_protection(self):
    response = self.client.get("/")
    # X-Frame-Options header
    assert response["X-Frame-Options"] == "DENY"
    # Or CSP frame-ancestors
    csp = response.get("Content-Security-Policy", "")
    assert "frame-ancestors 'none'" in csp or response["X-Frame-Options"] == "DENY"
```

## Red Flags

- No `X_FRAME_OPTIONS` in settings
- `X_FRAME_OPTIONS = "ALLOWALL"` — allows clickjacking
- `@xframe_options_exempt` on sensitive views (login, settings, admin)
- Missing both `X-Frame-Options` and CSP `frame-ancestors`
- `XFrameOptionsMiddleware` removed from MIDDLEWARE

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
