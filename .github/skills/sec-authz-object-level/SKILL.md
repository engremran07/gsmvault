---
name: sec-authz-object-level
description: "Object-level permissions: ownership checks, per-object perms. Use when: restricting access to specific model instances, ownership enforcement."
---

# Object-Level Permissions

## When to Use

- Ensuring users can only access their own resources
- Per-object permission checks in views and API
- Ownership validation before update/delete operations

## Rules

| Rule | Implementation |
|------|----------------|
| Always filter by user | `.filter(user=request.user)` |
| Check before mutating | Verify ownership before update/delete |
| 404 not 403 | Return 404 for missing/unauthorized objects (no enumeration) |
| DRF `has_object_permission` | Use for ViewSet-level enforcement |

## Patterns

### View-Level Ownership Check
```python
from django.shortcuts import get_object_or_404

def edit_comment(request: HttpRequest, pk: int) -> HttpResponse:
    # Ownership check: user can only edit their own comments
    comment = get_object_or_404(Comment, pk=pk, author=request.user)
    if request.method == "POST":
        form = CommentForm(request.POST, instance=comment)
        if form.is_valid():
            form.save()
            return redirect("comments:detail", pk=pk)
    ...
```

### DRF Object Permission
```python
from rest_framework.permissions import BasePermission

class IsOwner(BasePermission):
    def has_object_permission(self, request, view, obj) -> bool:
        return obj.user == request.user

class IsOwnerOrReadOnly(BasePermission):
    def has_object_permission(self, request, view, obj) -> bool:
        if request.method in ("GET", "HEAD", "OPTIONS"):
            return True
        return obj.user == request.user
```

### Service Layer Ownership
```python
def update_profile(user: User, data: dict) -> UserProfile:
    """Update user's own profile — ownership implicit via user param."""
    profile = UserProfile.objects.get(user=user)
    for field, value in data.items():
        setattr(profile, field, value)
    profile.save()
    return profile

def delete_download_token(user: User, token_id: int) -> None:
    """Delete token — ownership enforced by filter."""
    deleted, _ = DownloadToken.objects.filter(
        pk=token_id, user=user
    ).delete()
    if not deleted:
        raise PermissionError("Token not found or not owned by user")
```

### QuerySet Scoping
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, IsOwner]

    def get_queryset(self):
        # Users only see their own uploads
        return Firmware.objects.filter(uploaded_by=self.request.user)
```

## Red Flags

- `Firmware.objects.get(pk=pk)` without user filter — allows access to any object
- Returning 403 instead of 404 — reveals object existence
- Staff bypass without explicit check
- Missing ownership check in update/delete views

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
