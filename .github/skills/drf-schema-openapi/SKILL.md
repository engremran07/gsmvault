---
name: drf-schema-openapi
description: "OpenAPI schema generation: drf-spectacular, endpoint documentation. Use when: generating API docs, OpenAPI/Swagger specs, documenting endpoints with examples."
---

# DRF OpenAPI Schema Generation

## When to Use
- Generating OpenAPI 3.0 specification for the API
- Auto-generating Swagger/ReDoc documentation pages
- Adding request/response examples to API docs
- Documenting custom actions and permissions

## Rules
- Use `drf-spectacular` (not `drf-yasg` — deprecated)
- Schema generation is automatic from serializers + viewsets
- Add `@extend_schema` for custom endpoints or overrides
- Serve docs at `/api/docs/` (Swagger UI) and `/api/redoc/` (ReDoc)

## Patterns

### Installation & Settings
```python
INSTALLED_APPS = [
    "drf_spectacular",
]

REST_FRAMEWORK = {
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
}

SPECTACULAR_SETTINGS = {
    "TITLE": "GSMFWs API",
    "DESCRIPTION": "Enterprise firmware distribution platform API",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
    "COMPONENT_SPLIT_REQUEST": True,
    "SCHEMA_PATH_PREFIX": "/api/v[0-9]",
}
```

### URL Configuration
```python
# app/urls.py
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)

urlpatterns = [
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger"),
    path("api/redoc/", SpectacularRedocView.as_view(url_name="schema"), name="redoc"),
]
```

### @extend_schema on ViewSet
```python
from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiExample

class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.all()
    serializer_class = FirmwareSerializer

    @extend_schema(
        summary="List firmwares",
        description="Returns paginated list of firmwares. Supports search and filtering.",
        parameters=[
            OpenApiParameter("search", str, description="Search by name or version"),
            OpenApiParameter("brand", str, description="Filter by brand slug"),
        ],
        responses={200: FirmwareSerializer(many=True)},
    )
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)
```

### Documenting Custom Actions
```python
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import serializers

class FirmwareViewSet(viewsets.ModelViewSet):
    @extend_schema(
        summary="Approve firmware",
        description="Staff-only: approve a pending firmware for distribution.",
        request=None,
        responses={
            200: inline_serializer("ApproveResponse", fields={
                "status": serializers.CharField(),
            }),
            403: inline_serializer("ForbiddenResponse", fields={
                "error": serializers.CharField(),
                "code": serializers.CharField(),
            }),
        },
    )
    @action(detail=True, methods=["post"], permission_classes=[IsAdminUser])
    def approve(self, request, pk=None):
        firmware = self.get_object()
        firmware.status = "approved"
        firmware.save(update_fields=["status"])
        return Response({"status": "approved"})
```

### Request/Response Examples
```python
@extend_schema(
    examples=[
        OpenApiExample(
            "Create firmware",
            value={"name": "Samsung_A52_V1.2", "version": "1.2.0", "brand": 1},
            request_only=True,
        ),
        OpenApiExample(
            "Firmware response",
            value={
                "id": 42, "name": "Samsung_A52_V1.2",
                "version": "1.2.0", "brand": {"id": 1, "name": "Samsung"},
                "created_at": "2025-01-15T10:00:00Z",
            },
            response_only=True,
        ),
    ],
)
def create(self, request, *args, **kwargs):
    return super().create(request, *args, **kwargs)
```

### Tagging Endpoints
```python
@extend_schema(tags=["Firmware Management"])
class FirmwareViewSet(viewsets.ModelViewSet):
    ...

@extend_schema(tags=["Authentication"])
class LoginView(APIView):
    ...
```

### Excluding Endpoints from Schema
```python
from drf_spectacular.utils import extend_schema

@extend_schema(exclude=True)
class InternalHealthView(APIView):
    """Internal-only endpoint, hidden from public docs."""
    ...
```

## Anti-Patterns
- No API documentation → clients can't use the API
- Manual OpenAPI YAML → drifts from actual implementation
- `drf-yasg` → unmaintained, use `drf-spectacular`
- Missing examples → docs are hard to understand

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `api-design` — API design conventions
- Skill: `drf-viewsets-custom` — custom action documentation
