---
name: drf-versioning-header
description: "Header-based API versioning: Accept header, custom version headers. Use when: versioning API via HTTP headers instead of URL path, implementing content-type versioning."
---

# DRF Header-Based Versioning

## When to Use
- API versioning without changing URL structure
- Content-type negotiation with version (GitHub API style)
- When URL-based versioning is not suitable for the use case

## Rules
- Header versioning keeps URLs clean but is less discoverable
- Platform default is URL-based — use header versioning only for specific APIs
- Client sends `Accept: application/json; version=2` or custom header
- Always provide a default version for clients that don't specify

## Patterns

### Accept Header Versioning
```python
# app/settings.py (per-ViewSet override, not global)
# Global stays URLPathVersioning; use per-view for header-versioned endpoints.
```

```python
from rest_framework.versioning import AcceptHeaderVersioning

class HeaderVersionedViewSet(viewsets.ModelViewSet):
    versioning_class = AcceptHeaderVersioning
    # Client: Accept: application/json; version=1.0
```

### Custom Header Versioning
```python
from rest_framework.versioning import BaseVersioning

class CustomHeaderVersioning(BaseVersioning):
    """Version via X-API-Version header."""
    default_version = "1"
    allowed_versions = ("1", "2")

    def determine_version(self, request, *args, **kwargs) -> str:
        version = request.headers.get("X-API-Version", self.default_version)
        if version not in self.allowed_versions:
            from rest_framework.exceptions import NotFound
            raise NotFound(f"API version '{version}' not supported.")
        return version
```

### ViewSet Usage
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    versioning_class = CustomHeaderVersioning

    def get_serializer_class(self):
        if self.request.version == "2":
            return FirmwareV2Serializer
        return FirmwareSerializer
```

### Client Request Examples
```bash
# Accept header versioning
curl -H "Accept: application/json; version=2" \
     https://api.example.com/api/firmwares/

# Custom header versioning
curl -H "X-API-Version: 2" \
     https://api.example.com/api/firmwares/
```

### Versioned Response Headers
```python
class VersionedResponseMixin:
    def finalize_response(self, request, response, *args, **kwargs):
        response = super().finalize_response(request, response, *args, **kwargs)
        response["X-API-Version"] = getattr(request, "version", "1")
        return response
```

### Combining URL + Header (Hybrid)
```python
class HybridVersioning(BaseVersioning):
    """URL version takes precedence, falls back to header."""
    default_version = "1"

    def determine_version(self, request, *args, **kwargs):
        # Check URL first
        url_version = kwargs.get("version")
        if url_version:
            return url_version
        # Fall back to header
        return request.headers.get("X-API-Version", self.default_version)
```

### Version-Aware Serializer Selection
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    versioning_class = CustomHeaderVersioning
    serializer_versions = {
        "1": FirmwareSerializer,
        "2": FirmwareV2Serializer,
    }

    def get_serializer_class(self):
        version = getattr(self.request, "version", "1")
        return self.serializer_versions.get(version, FirmwareSerializer)
```

## Anti-Patterns
- No default version → clients without header get errors
- Mixing URL and header versioning inconsistently → confusion
- Not documenting required headers → clients don't know how to version
- Version in body/query param → not idiomatic REST

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-versioning-url` — URL path versioning (platform default)
- Skill: `drf-content-negotiation` — content type handling
