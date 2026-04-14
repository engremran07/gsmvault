---
applyTo: 'apps/*/api.py'
---

# DRF API Conventions

## Serializers

Use `ModelSerializer` with explicit fields — never `fields = "__all__"`:

```python
from rest_framework import serializers
from .models import Firmware

class FirmwareSerializer(serializers.ModelSerializer):
    brand_name = serializers.CharField(source="brand.name", read_only=True)

    class Meta:
        model = Firmware
        fields = [
            "id", "name", "description", "brand", "brand_name",
            "model", "status", "file_size", "created_at",
        ]
        read_only_fields = ["id", "status", "created_at"]
```

## ViewSets

Use `ModelViewSet` for standard CRUD, with explicit queryset and permissions:

```python
from rest_framework import viewsets, permissions
from apps.core.throttling import APIRateThrottle

class FirmwareViewSet(viewsets.ModelViewSet):
    serializer_class = FirmwareSerializer
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [APIRateThrottle]

    def get_queryset(self) -> QuerySet[Firmware]:
        return Firmware.objects.filter(
            is_active=True
        ).select_related("brand", "model")
```

## Authentication

JWT authentication via PyJWT + session auth for browser access:

```python
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
        "rest_framework.authentication.SessionAuthentication",
    ],
}
```

## Pagination

Cursor-based pagination for large datasets:

```python
from rest_framework.pagination import CursorPagination

class FirmwareCursorPagination(CursorPagination):
    page_size = 25
    ordering = "-created_at"
    cursor_query_param = "cursor"
```

## Error Responses

Consistent error format across all endpoints:

```python
from apps.core.exceptions import json_error_response

# Standard error response
return json_error_response(
    error="Firmware not found",
    code="FIRMWARE_NOT_FOUND",
    status=404,
)

# Format: {"error": "message", "code": "ERROR_CODE"}
```

## Rate Limiting

Use DRF throttle classes from `apps.core.throttling`:

```python
from apps.core.throttling import (
    APIRateThrottle,       # General API: 100/min
    UploadRateThrottle,    # File uploads: 10/min
    DownloadRateThrottle,  # Downloads: based on tier
)

class FirmwareUploadView(APIView):
    throttle_classes = [UploadRateThrottle]
```

## URL Prefix

All API endpoints under `/api/v1/`:

```python
# apps/api/urls.py
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register("firmwares", FirmwareViewSet, basename="firmware")

urlpatterns = [
    path("", include(router.urls)),
]
```

## Custom Actions

Use `@action` decorator for non-CRUD endpoints:

```python
from rest_framework.decorators import action

class FirmwareViewSet(viewsets.ModelViewSet):
    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAdminUser])
    def approve(self, request: Request, pk: int = None) -> Response:
        firmware = self.get_object()
        approve_firmware(firmware, approved_by=request.user)
        return Response({"status": "approved"})
```

## Filtering and Search

Use `django-filter` for querystring filtering:

```python
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

class FirmwareViewSet(viewsets.ModelViewSet):
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ["brand", "status", "firmware_type"]
    search_fields = ["name", "description"]
    ordering_fields = ["created_at", "name", "download_count"]
```
