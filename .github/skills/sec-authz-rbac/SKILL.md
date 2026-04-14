---
name: sec-authz-rbac
description: "Role-based access control: groups, permissions, custom roles. Use when: assigning permissions to user groups, restricting feature access by role."
---

# Role-Based Access Control

## When to Use

- Assigning permissions to user groups (admin, moderator, tester)
- Restricting features by subscription tier
- Configuring Django groups and permissions

## Rules

| Role | Group | Key Permissions |
|------|-------|----------------|
| Admin | `admin` | All permissions |
| Moderator | `moderator` | `change_forumtopic`, `delete_forumreply`, `change_comment` |
| Tester | `trusted_tester` | `add_verificationreport`, `change_firmware` |
| Publisher | `publisher` | `add_post`, `change_post`, `publish_post` |

## Patterns

### Group-Based Permission Check
```python
from django.contrib.auth.decorators import login_required, user_passes_test

def is_moderator(user) -> bool:
    return user.groups.filter(name="moderator").exists()

@login_required
@user_passes_test(is_moderator)
def moderate_content(request: HttpRequest) -> HttpResponse:
    ...
```

### DRF Permission Class
```python
from rest_framework.permissions import BasePermission

class IsModerator(BasePermission):
    def has_permission(self, request, view) -> bool:
        return (
            request.user.is_authenticated
            and request.user.groups.filter(name="moderator").exists()
        )

class IsSubscriber(BasePermission):
    def has_permission(self, request, view) -> bool:
        return (
            request.user.is_authenticated
            and hasattr(request.user, "subscription")
            and request.user.subscription.is_active
        )
```

### Management Command for Group Setup
```python
from django.core.management.base import BaseCommand
from django.contrib.auth.models import Group, Permission

class Command(BaseCommand):
    def handle(self, **options):
        moderator, _ = Group.objects.get_or_create(name="moderator")
        perms = Permission.objects.filter(
            codename__in=["change_forumtopic", "delete_forumreply", "change_comment"]
        )
        moderator.permissions.set(perms)
        self.stdout.write("Moderator group configured.")
```

### Template Permission Check
```html
{% if perms.firmwares.add_firmware %}
    <a href="{% url 'firmwares:upload' %}">Upload Firmware</a>
{% endif %}
```

## Red Flags

- Hardcoded `user.id == 1` checks instead of group/permission checks
- Permission checks in templates but not in views (byppassable)
- Groups without explicit permission assignment
- `is_superuser` check where specific permission would suffice

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
