---
name: drf-caching-response
description: "Response caching: cache_page, ETags, conditional requests. Use when: caching API responses, adding ETag support, conditional GET requests, HTTP cache headers."
---

# DRF Response Caching

## When to Use
- Caching expensive list/detail API responses
- Adding ETag headers for conditional requests
- Reducing database load on read-heavy endpoints
- Client-side cache validation with `If-None-Match`

## Rules
- Cache only GET/HEAD responses — never cache mutating requests
- Use `cache_page()` for time-based caching
- Use ETags for content-based cache validation
- Invalidate cache on create/update/delete operations
- Use `apps.core.cache.DistributedCacheManager` for complex scenarios

## Patterns

### Simple Time-Based Cache
```python
from django.views.decorators.cache import cache_page
from django.utils.decorators import method_decorator
from rest_framework import viewsets

class BrandViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Brand.objects.filter(is_active=True)
    serializer_class = BrandSerializer

    @method_decorator(cache_page(60 * 15))  # 15 minutes
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)
```

### Per-User Cache (Vary by Auth)
```python
from django.views.decorators.vary import vary_on_headers

class FirmwareViewSet(viewsets.ModelViewSet):
    @method_decorator(cache_page(60 * 5))
    @method_decorator(vary_on_headers("Authorization"))
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)
```

### ETag Support
```python
import hashlib
from rest_framework.response import Response
from rest_framework import status

class ETagMixin:
    """Add ETag support to ViewSet retrieve/list actions."""

    def _compute_etag(self, data) -> str:
        import json
        content = json.dumps(data, sort_keys=True, default=str)
        return hashlib.md5(content.encode()).hexdigest()  # noqa: S324

    def finalize_response(self, request, response, *args, **kwargs):
        response = super().finalize_response(request, response, *args, **kwargs)

        if request.method in ("GET", "HEAD") and response.status_code == 200:
            etag = f'"{self._compute_etag(response.data)}"'
            response["ETag"] = etag

            # Check If-None-Match
            if_none_match = request.headers.get("If-None-Match")
            if if_none_match and if_none_match == etag:
                response.status_code = status.HTTP_304_NOT_MODIFIED
                response.data = None

        return response
```

### ViewSet with ETag
```python
class FirmwareViewSet(ETagMixin, viewsets.ReadOnlyModelViewSet):
    queryset = Firmware.objects.select_related("brand").all()
    serializer_class = FirmwareSerializer
```

### Cache-Control Headers
```python
from django.utils.cache import patch_cache_control

class CacheControlMixin:
    cache_max_age = 300  # 5 minutes

    def finalize_response(self, request, response, *args, **kwargs):
        response = super().finalize_response(request, response, *args, **kwargs)
        if request.method in ("GET", "HEAD"):
            patch_cache_control(
                response,
                max_age=self.cache_max_age,
                public=not request.user.is_authenticated,
                private=request.user.is_authenticated,
            )
        return response
```

### Manual Cache with Invalidation
```python
from django.core.cache import cache

class FirmwareViewSet(viewsets.ModelViewSet):
    def list(self, request, *args, **kwargs):
        cache_key = f"firmware_list_{request.query_params.urlencode()}"
        cached = cache.get(cache_key)
        if cached:
            return Response(cached)

        response = super().list(request, *args, **kwargs)
        cache.set(cache_key, response.data, timeout=300)
        return response

    def perform_create(self, serializer):
        serializer.save()
        # Invalidate list caches
        cache.delete_pattern("firmware_list_*")

    def perform_update(self, serializer):
        serializer.save()
        cache.delete_pattern("firmware_list_*")
```

## Anti-Patterns
- Caching authenticated responses without `Vary: Authorization` → user data leak
- Caching POST/PUT/DELETE responses → stale mutations
- No cache invalidation on writes → stale reads
- MD5 for security (it's fine for ETags, not for passwords)
- `cache_page` on user-specific data without varying → wrong user sees cached data

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `apps/core/cache.py` — DistributedCacheManager
- Skill: `services-cache-strategy` — caching architecture
