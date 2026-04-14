---
name: drf-permissions-role
description: "Role-based permissions: IsAdminUser, custom IsStaff, tier-based. Use when: restricting API access by user role, subscription tier, or staff status."
---

# DRF Role-Based Permissions

## When to Use
- Restricting endpoints to staff/admin users
- Tier-based access (free, registered, subscriber, premium)
- Combining multiple role checks on a single endpoint

## Rules
- Use DRF built-in `IsAdminUser` for admin-only endpoints
- Custom permissions inherit from `BasePermission`
- Always use `getattr(request.user, "field", False)` for anonymous-safe checks
- Tier checks query the user's subscription/quota tier from `apps.devices.QuotaTier`

## Patterns

### Staff-Only Permission
```python
from rest_framework.permissions import BasePermission

class IsStaffUser(BasePermission):
    """Allows access only to staff users."""

    def has_permission(self, request, view) -> bool:
        return bool(
            request.user
            and request.user.is_authenticated
            and getattr(request.user, "is_staff", False)
        )
```

### Tier-Based Permission
```python
class IsPremiumUser(BasePermission):
    """Only premium-tier users can access."""
    message = "Premium subscription required."

    def has_permission(self, request, view) -> bool:
        if not request.user.is_authenticated:
            return False
        # Check user's subscription tier
        profile = getattr(request.user, "profile", None)
        if profile is None:
            return False
        return profile.tier in ("premium", "enterprise")


class IsSubscriber(BasePermission):
    """Subscriber tier or above."""
    message = "Subscription required."

    def has_permission(self, request, view) -> bool:
        if not request.user.is_authenticated:
            return False
        profile = getattr(request.user, "profile", None)
        if profile is None:
            return False
        return profile.tier in ("subscriber", "premium", "enterprise")
```

### Combining Permissions (AND Logic)
```python
class AdminReportViewSet(viewsets.ReadOnlyModelViewSet):
    """Staff AND authenticated (AND is default with list)."""
    permission_classes = [IsAuthenticated, IsStaffUser]
    queryset = AuditLog.objects.all()
    serializer_class = AuditLogSerializer
```

### OR Logic with Custom Permission
```python
class IsStaffOrReadOnly(BasePermission):
    """Staff can do anything; others get read-only."""

    def has_permission(self, request, view) -> bool:
        if request.method in SAFE_METHODS:
            return True
        return bool(
            request.user
            and request.user.is_authenticated
            and getattr(request.user, "is_staff", False)
        )
```

### ViewSet with Mixed Role Permissions
```python
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()

    def get_permissions(self):
        if self.action == "list":
            return [IsStaffUser()]
        if self.action == "create":
            return [permissions.AllowAny()]
        if self.action in ("update", "partial_update"):
            return [permissions.IsAuthenticated(), IsOwnerOrStaff()]
        if self.action == "destroy":
            return [IsStaffUser()]
        return [permissions.IsAuthenticated()]
```

### Custom Error Message
```python
class IsVerifiedTester(BasePermission):
    message = "Only verified testers can access this resource."
    code = "TESTER_REQUIRED"

    def has_permission(self, request, view) -> bool:
        if not request.user.is_authenticated:
            return False
        return hasattr(request.user, "tester_profile") and (
            request.user.tester_profile.is_verified  # type: ignore[attr-defined]
        )
```

## Anti-Patterns
- Using `request.user.is_staff` without `getattr` → `AnonymousUser` crash
- Empty `permission_classes = []` → endpoint is completely open
- Checking roles in the view body instead of permission class → scattered auth logic
- OR logic by listing two permissions (DRF uses AND by default)

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-permissions-object` — object-level ownership checks
- Skill: `drf-authentication-jwt` — JWT auth integration
