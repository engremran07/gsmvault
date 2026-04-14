---
name: sec-cors-config
description: "CORS configuration: CORS_ALLOWED_ORIGINS, preflight handling. Use when: configuring cross-origin API access, django-cors-headers setup."
---

# CORS Configuration

## When to Use

- Configuring cross-origin API access
- Setting up `django-cors-headers`
- Handling preflight requests for AJAX/fetch calls

## Rules

| Setting | Purpose | Value |
|---------|---------|-------|
| `CORS_ALLOWED_ORIGINS` | Explicit origin allowlist | List of full origins |
| `CORS_ALLOW_CREDENTIALS` | Allow cookies cross-origin | `True` only if needed |
| `CORS_ALLOW_ALL_ORIGINS` | Allow any origin | **NEVER in production** |
| `CORS_URLS_REGEX` | Limit CORS to specific paths | API paths only |

## Patterns

### django-cors-headers Setup
```python
# settings.py
INSTALLED_APPS = [
    "corsheaders",
    ...
]
MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",  # Must be before CommonMiddleware
    "django.middleware.common.CommonMiddleware",
    ...
]
```

### Production Configuration
```python
# settings_production.py
CORS_ALLOWED_ORIGINS = [
    "https://gsmfws.com",
    "https://www.gsmfws.com",
    "https://admin.gsmfws.com",
]
CORS_URLS_REGEX = r"^/api/.*$"  # Only API paths
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_HEADERS = [
    "accept", "authorization", "content-type",
    "x-csrftoken", "x-requested-with", "hx-request",
    "hx-target", "hx-trigger",
]
CORS_ALLOW_METHODS = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
CORS_EXPOSE_HEADERS = ["Content-Disposition", "X-Request-Id"]
```

### Development Override
```python
# settings_dev.py
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",  # Frontend dev server
    "http://localhost:8000",
    "http://127.0.0.1:8000",
]
# CORS_ALLOW_ALL_ORIGINS = True  # OK in dev, NEVER in prod
```

### Preflight Cache
```python
# Cache preflight responses for 1 hour
CORS_PREFLIGHT_MAX_AGE = 3600
```

### Per-View CORS (Rare)
```python
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse

@csrf_exempt  # Only for genuinely public API endpoints
def public_health_check(request):
    response = JsonResponse({"status": "ok"})
    response["Access-Control-Allow-Origin"] = "*"
    return response
```

## Red Flags

- `CORS_ALLOW_ALL_ORIGINS = True` in production — allows any site to access API
- `CORS_ALLOW_CREDENTIALS = True` with `CORS_ALLOW_ALL_ORIGINS = True` — critical vulnerability
- `CorsMiddleware` not before `CommonMiddleware`
- No `CORS_URLS_REGEX` — CORS headers on all paths including admin
- Missing HTMX headers in `CORS_ALLOW_HEADERS` when using HTMX

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
