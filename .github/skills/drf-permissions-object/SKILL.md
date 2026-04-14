---
name: drf-permissions-object
description: "Object-level permissions: has_object_permission, ownership checks. Use when: restricting access to individual objects based on ownership, roles, or custom logic."
---

# DRF Object-Level Permissions

## When to Use
- Users should only access their own resources
- Staff can access all, non-staff limited to owned objects
- Different permission logic for read vs write on individual objects

## Rules
- Implement `has_object_permission()` — DRF calls it on `get_object()`
- Object permissions are NOT checked on list actions — filter in `get_queryset()`
- Always check `has_permission()` first (view-level), then `has_object_permission()`
- Use `getattr(request.user, "is_staff", False)` for anonymous-safe staff checks

## Patterns

### Owner-Or-Staff Permission
```python
from rest_framework.permissions import BasePermission

class IsOwnerOrStaff(BasePermission):
    """Object owner or staff can access."""

    def has_object_permission(self, request, view, obj) -> bool:
        if getattr(request.user, "is_staff", False):
            return True
        return hasattr(obj, "owner") and obj.owner == request.user
```

### Read-Any / Write-Owner
```python
from rest_framework.permissions import BasePermission, SAFE_METHODS

class IsOwnerOrReadOnly(BasePermission):
    """Anyone can read; only the owner can modify."""

    def has_object_permission(self, request, view, obj) -> bool:
        if request.method in SAFE_METHODS:
            return True
        return obj.owner == request.user
```

### Field-Based Ownership (user FK named differently)
```python
class IsAuthorOrStaff(BasePermission):
    """Works with models where the owner field is 'author'."""

    def has_object_permission(self, request, view, obj) -> bool:
        if getattr(request.user, "is_staff", False):
            return True
        return getattr(obj, "author", None) == request.user
```

### Combining Permissions in ViewSet
```python
from rest_framework import viewsets, permissions

class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.all()
    serializer_class = FirmwareSerializer

    def get_permissions(self):
        if self.action in ("list", "retrieve"):
            return [permissions.IsAuthenticatedOrReadOnly()]
        if self.action in ("update", "partial_update", "destroy"):
            return [permissions.IsAuthenticated(), IsOwnerOrStaff()]
        return [permissions.IsAuthenticated()]
```

### Per-Action Permission on Custom Actions
```python
from rest_framework.decorators import action

class TopicViewSet(viewsets.ModelViewSet):
    @action(
        detail=True,
        methods=["post"],
        permission_classes=[permissions.IsAuthenticated, IsOwnerOrStaff],
    )
    def pin(self, request, pk=None):
        topic = self.get_object()  # triggers has_object_permission
        topic.is_pinned = True
        topic.save(update_fields=["is_pinned"])
        return Response({"status": "pinned"})
```

### Queryset Scoping (List-Level Equivalent)
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    """Object perms don't run on list — scope queryset instead."""

    def get_queryset(self):
        user = self.request.user
        qs = Firmware.objects.select_related("brand")
        if not getattr(user, "is_staff", False):
            qs = qs.filter(uploaded_by=user)
        return qs
```

## Anti-Patterns
- Only implementing `has_object_permission` without queryset scoping → list exposes all objects
- Using `request.user.is_staff` directly → crashes on `AnonymousUser`
- Forgetting that `has_object_permission` is NOT called on `list` action
- Hardcoding user FK name → breaks when models use `author`, `uploaded_by`, etc.

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-permissions-role` — role-based permission patterns
- Skill: `drf-viewsets-model` — ViewSet permission_classes wiring
