---
name: drf-viewsets-model
description: "ModelViewSet patterns: queryset, serializer_class, permission_classes. Use when: creating standard CRUD API endpoints for a Django model."
---

# DRF ModelViewSet Patterns

## When to Use
- Building standard CRUD API for a model
- Need list, retrieve, create, update, destroy actions
- Setting up router-registered endpoints

## Rules
- Always set `queryset` with proper `select_related()` / `prefetch_related()`
- Always set `permission_classes` — never rely on global defaults alone
- Use `get_queryset()` to scope results to requesting user (unless staff)
- Use `get_serializer_class()` to switch between list/detail serializers
- Wire via `DefaultRouter` in `urls.py`

## Patterns

### Standard ModelViewSet
```python
from rest_framework import viewsets, permissions, filters
from .models import Firmware
from .api import FirmwareSerializer

class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.select_related("brand", "model").all()
    serializer_class = FirmwareSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["name", "version", "brand__name"]
    ordering_fields = ["created_at", "name", "file_size"]
    ordering = ["-created_at"]
```

### Scoped Queryset (User Ownership)
```python
class UserFirmwareViewSet(viewsets.ModelViewSet):
    serializer_class = FirmwareSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if getattr(self.request.user, "is_staff", False):
            return Firmware.objects.select_related("brand").all()
        return Firmware.objects.select_related("brand").filter(
            uploaded_by=self.request.user
        )
```

### Separate List / Detail Serializers
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.select_related("brand").all()
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_serializer_class(self):
        if self.action == "list":
            return FirmwareListSerializer
        return FirmwareDetailSerializer
```

### ReadOnlyModelViewSet (Public Data)
```python
class BrandViewSet(viewsets.ReadOnlyModelViewSet):
    """Public read-only endpoint — no create/update/delete."""
    queryset = Brand.objects.filter(is_active=True)
    serializer_class = BrandSerializer
    permission_classes = [permissions.AllowAny]
```

### perform_create / perform_update Hooks
```python
class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

    def perform_update(self, serializer):
        serializer.save(updated_by=self.request.user)
```

### Router Registration
```python
# apps/<app>/urls.py
from rest_framework.routers import DefaultRouter
from .api import FirmwareViewSet, BrandViewSet

app_name = "firmwares"
router = DefaultRouter()
router.register("firmwares", FirmwareViewSet, basename="firmware")
router.register("brands", BrandViewSet, basename="brand")
urlpatterns = router.urls
```

### Mixed Permissions (Read Public, Write Auth)
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.all()
    serializer_class = FirmwareSerializer

    def get_permissions(self):
        if self.action in ("list", "retrieve"):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]
```

## Anti-Patterns
- Missing `select_related` → N+1 queries on nested serializer
- No `get_queryset()` scoping → users see other users' data
- `permission_classes = []` → endpoint is wide open
- Heavy logic in `perform_create()` → use `services.py` for complex flows
- Using `APIView` when `ModelViewSet` covers the use case

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-viewsets-custom` — `@action` decorator for extra routes
- Skill: `drf-permissions-object` — object-level permission checks
