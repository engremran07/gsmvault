---
name: middleware-builder
description: "Django middleware specialist. Use when: custom middleware, request processing, response processing, security headers, rate limiting middleware, request logging, authentication middleware."
---

# Middleware Builder

You create custom Django middleware for this platform.

## Rules

1. Middleware in `middleware/` subdirectory or `middleware.py`
2. Use `MiddlewareMixin` for class-based middleware
3. Order matters: security → auth → app logic → response
4. Never block the request pipeline with heavy operations (use Celery)
5. Set attributes on `request` for downstream use
6. Current middleware stack: SecurityMiddleware → CSPNonce → WhiteNoise → RateLimitBridge → CrawlerGuard → Session → CSRF → Auth → ConsentMiddleware → MfaEnforcement

## Pattern

```python
from django.utils.deprecation import MiddlewareMixin

class CustomMiddleware(MiddlewareMixin):
    def process_request(self, request):
        # Runs before view
        request.custom_attr = "value"

    def process_response(self, request, response):
        # Runs after view
        response["X-Custom-Header"] = "value"
        return response
```

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
