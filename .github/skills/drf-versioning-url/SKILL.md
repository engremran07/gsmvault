---
name: drf-versioning-url
description: "URL-based versioning: /api/v1/, /api/v2/ namespace strategy. Use when: structuring API versions via URL path, adding new API versions, maintaining backward compatibility."
---

# DRF URL-Based Versioning

## When to Use
- Structuring API under `/api/v1/`, `/api/v2/` paths
- Adding a new API version while maintaining the old one
- Platform default versioning strategy

## Rules
- URL versioning is the platform's chosen strategy — `/api/v1/` prefix
- New versions get new URL prefix — old versions stay unchanged
- Version-specific serializers and views when behavior differs
- Shared models — never duplicate models for versioning

## Patterns

### URL Configuration
```python
# app/urls.py
from django.urls import include, path

urlpatterns = [
    path("api/v1/", include("apps.api.urls_v1", namespace="api-v1")),
    # Future: path("api/v2/", include("apps.api.urls_v2", namespace="api-v2")),
]
```

### Version-Specific URL Module
```python
# apps/api/urls_v1.py
from django.urls import include, path

app_name = "api-v1"

urlpatterns = [
    path("firmwares/", include("apps.firmwares.urls")),
    path("devices/", include("apps.devices.urls")),
    path("users/", include("apps.users.urls")),
    path("auth/", include("apps.users.auth_urls")),
]
```

### Settings
```python
REST_FRAMEWORK = {
    "DEFAULT_VERSIONING_CLASS": "rest_framework.versioning.URLPathVersioning",
    "DEFAULT_VERSION": "v1",
    "ALLOWED_VERSIONS": ["v1"],
    "VERSION_PARAM": "version",
}
```

### Checking Version in Views
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    def get_serializer_class(self):
        if self.request.version == "v2":
            return FirmwareV2Serializer
        return FirmwareSerializer

    def get_queryset(self):
        qs = Firmware.objects.select_related("brand")
        if self.request.version == "v2":
            qs = qs.filter(is_active=True)  # v2 only shows active
        return qs
```

### Version-Specific Serializers
```python
class FirmwareSerializer(serializers.ModelSerializer):
    """V1 serializer — original fields."""
    class Meta:
        model = Firmware
        fields = ["id", "name", "version", "brand", "created_at"]

class FirmwareV2Serializer(serializers.ModelSerializer):
    """V2 serializer — enhanced response."""
    brand = BrandMinimalSerializer(read_only=True)
    download_url = serializers.SerializerMethodField()

    class Meta:
        model = Firmware
        fields = ["id", "name", "version", "brand", "download_url", "created_at"]

    def get_download_url(self, obj) -> str | None:
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(f"/api/v2/firmwares/{obj.pk}/download/")
        return None
```

### Deprecation Headers
```python
from rest_framework.response import Response

class DeprecatedV1Mixin:
    """Add deprecation warning to V1 responses."""

    def finalize_response(self, request, response, *args, **kwargs):
        response = super().finalize_response(request, response, *args, **kwargs)
        if getattr(request, "version", None) == "v1":
            response["Deprecation"] = "true"
            response["Sunset"] = "2026-12-31"
            response["Link"] = '</api/v2/>; rel="successor-version"'
        return response
```

## Anti-Patterns
- Duplicating models per version → use the same models, vary serializers
- Breaking V1 when adding V2 → V1 must be frozen
- No deprecation plan → old versions linger indefinitely
- Version in query param (`?version=2`) → less discoverable than URL path

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-versioning-header` — header-based alternative
- Skill: `urls-namespaces` — URL namespace patterns
