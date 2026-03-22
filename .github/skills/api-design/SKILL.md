---
name: api-design
description: "Design REST API endpoints with Django REST Framework. Use when: creating serializers, viewsets, routers, custom permissions, pagination, filtering, or API versioning for the platform."
---

# API Design

## When to Use
- Creating or extending API endpoints
- Designing serializer schemas for new models
- Adding authentication, permissions, or rate limiting
- Structuring URL routing under `/api/v1/`

## Rules
- NEVER return raw dicts — always use DRF serializers
- Business logic belongs in `services.py`, NOT in views or serializers
- All list endpoints require pagination
- All mutating endpoints require authentication
- Error responses must use `{"error": "...", "code": "..."}` format

## Procedure

### Step 1: Define Serializer
In `apps/<app>/api.py`:
```python
from rest_framework import serializers
from .models import MyModel

class MyModelSerializer(serializers.ModelSerializer):
    class Meta:
        model = MyModel
        fields = ["id", "name", "status", "created_at"]
        read_only_fields = ["id", "created_at"]
```

### Step 2: Create ViewSet
```python
from rest_framework import viewsets, permissions, filters

class MyModelViewSet(viewsets.ModelViewSet):
    queryset = MyModel.objects.select_related("owner").all()
    serializer_class = MyModelSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["name"]
    ordering_fields = ["created_at", "name"]
    ordering = ["-created_at"]

    def get_queryset(self):
        # Scope to the requesting user unless staff
        qs = super().get_queryset()
        if not self.request.user.is_staff:
            qs = qs.filter(owner=self.request.user)
        return qs
```

### Step 3: Wire URLs
In `apps/<app>/urls.py`:
```python
from rest_framework.routers import DefaultRouter
from .api import MyModelViewSet

app_name = "myapp"
router = DefaultRouter()
router.register("mymodels", MyModelViewSet, basename="mymodel")
urlpatterns = router.urls
```

### Step 4: Quality Gate (MANDATORY — before and after)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

Zero issues in: VS Code Problems tab (all items, no active filters), ruff, Pyright/Pylance, `manage.py check`.
Fix every warning and type error before considering the task complete.

## Error Response Convention
```python
from rest_framework.response import Response
from rest_framework import status

# In a view:
return Response(
    {"error": "Not found", "code": "NOT_FOUND"},
    status=status.HTTP_404_NOT_FOUND,
)
```

## Pagination
Cursor pagination is configured globally in settings. Do not override unless you have a specific reason:
```python
REST_FRAMEWORK = {
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.CursorPagination",
    "PAGE_SIZE": 20,
}
```

## Custom Permissions
```python
from rest_framework.permissions import BasePermission

class IsOwnerOrStaff(BasePermission):
    def has_object_permission(self, request, view, obj):
        return request.user.is_staff or obj.owner == request.user
```

## Read-Only Public Endpoints
```python
from rest_framework.permissions import IsAuthenticatedOrReadOnly

class PublicViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticatedOrReadOnly]
```

## Serializer Field Alignment

Always verify that serializer `fields` match model field names **exactly**. This is a common source of silent 500 errors, especially after model consolidation (dissolved apps → target apps).

### Common Issues

- Field was renamed during consolidation (e.g., `device` → `device_model`) but serializer still references old name
- FK field uses `_id` suffix in the database but serializer uses the relation name
- `source=` kwarg on serializer field points to a removed/renamed model field

### Verification Pattern

```python
# Quick check: compare serializer fields to model fields
model_fields = {f.name for f in MyModel._meta.get_fields()}
serializer_fields = set(MyModelSerializer.Meta.fields)
mismatch = serializer_fields - model_fields - {"id"}  # id is always implicit
assert not mismatch, f"Serializer references non-existent fields: {mismatch}"
```

## Admin API Endpoints

Admin-only API endpoints are restricted to staff users and namespaced under `/api/v1/admin/`.

```python
from rest_framework.permissions import IsAdminUser
from rest_framework import viewsets

class AdminUserViewSet(viewsets.ModelViewSet):
    """Staff-only user management endpoint."""
    queryset = User.objects.all()
    serializer_class = AdminUserSerializer
    permission_classes = [IsAdminUser]
    filterset_fields = ["is_active", "is_staff", "date_joined"]
```

URL wiring:
```python
# app/urls.py
path("api/v1/admin/", include(("apps.admin.api_urls", "admin_api"), namespace="admin_api")),
```

Never expose admin endpoints under the regular `/api/v1/<app>/` namespace — always prefix with `/api/v1/admin/` for clarity and to support blanket permission enforcement via middleware.

## Bulk Operations

Batch create/update/delete patterns for admin API endpoints:

### Batch Delete

```python
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status

class MyModelViewSet(viewsets.ModelViewSet):
    @action(detail=False, methods=["post"], url_path="bulk-delete")
    def bulk_delete(self, request):
        ids = request.data.get("ids", [])
        if not ids or not isinstance(ids, list):
            return Response(
                {"error": "ids must be a non-empty list", "code": "INVALID_IDS"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        deleted_count, _ = self.get_queryset().filter(pk__in=ids).delete()
        return Response({"deleted": deleted_count})
```

### Batch Update

```python
    @action(detail=False, methods=["patch"], url_path="bulk-update")
    def bulk_update(self, request):
        ids = request.data.get("ids", [])
        updates = request.data.get("updates", {})
        if not ids or not updates:
            return Response(
                {"error": "ids and updates required", "code": "MISSING_PARAMS"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        # Validate allowed fields
        allowed = {"status", "is_active", "category"}
        invalid = set(updates.keys()) - allowed
        if invalid:
            return Response(
                {"error": f"Cannot update fields: {invalid}", "code": "INVALID_FIELDS"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        updated = self.get_queryset().filter(pk__in=ids).update(**updates)
        return Response({"updated": updated})
```
