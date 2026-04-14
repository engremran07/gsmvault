---
name: views-permission-checks
description: "Permission checking in views: staff checks, ownership validation, anonymous-safe patterns. Use when: protecting views, checking ownership, admin-only endpoints."
---

# Permission Checks in Views

## When to Use
- Protecting views from unauthorized access
- Staff-only admin endpoints
- Object ownership validation (user can only edit their own content)
- Anonymous-safe attribute access patterns

## Rules
- Always use `getattr(request.user, "is_staff", False)` — never bare `request.user.is_staff`
- Ownership checks: `.get(pk=pk, user=request.user)` or filter + 403
- Admin views use `_render_admin` decorator which enforces staff checks
- Never trust user-supplied IDs without an ownership check
- Views are orchestrators — they CAN import from multiple apps

## Patterns

### Anonymous-Safe Staff Check
```python
# CORRECT — safe for anonymous users:
if getattr(request.user, "is_staff", False):
    ...

# WRONG — crashes for AnonymousUser:
if request.user.is_staff:  # AttributeError on AnonymousUser
    ...
```

### Ownership Check — Filter Pattern
```python
@login_required
@require_http_methods(["GET", "POST"])
def edit_topic(request: HttpRequest, pk: int) -> HttpResponse:
    # Ownership check: user must own the topic OR be staff
    try:
        if getattr(request.user, "is_staff", False):
            topic = ForumTopic.objects.get(pk=pk)
        else:
            topic = ForumTopic.objects.get(pk=pk, author=request.user)
    except ForumTopic.DoesNotExist:
        raise Http404

    if request.method == "POST":
        form = TopicForm(request.POST, instance=topic)
        if form.is_valid():
            update_topic(topic, **form.cleaned_data)
            return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)
    else:
        form = TopicForm(instance=topic)

    return render(request, "forum/edit_topic.html", {"form": form, "topic": topic})
```

### Staff-Only with user_passes_test
```python
from django.contrib.auth.decorators import login_required, user_passes_test

def is_staff(user: Any) -> bool:
    return getattr(user, "is_staff", False)

@login_required
@user_passes_test(is_staff)
def admin_firmware_list(request: HttpRequest) -> HttpResponse:
    firmwares = Firmware.objects.all().select_related("brand")
    return render(request, "admin/firmwares/list.html", {"firmwares": firmwares})
```

### CBV Permission Pattern
```python
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin

class StaffOnlyView(LoginRequiredMixin, UserPassesTestMixin):
    def test_func(self) -> bool:
        return getattr(self.request.user, "is_staff", False)

class FirmwareAdminView(StaffOnlyView, ListView):
    model = Firmware
    template_name = "admin/firmwares/list.html"
```

### Object-Level Permission in Service
```python
# apps/forum/services.py
from django.core.exceptions import PermissionDenied

def delete_reply(reply_id: int, user: Any) -> None:
    reply = ForumReply.objects.get(pk=reply_id)
    if reply.author != user and not getattr(user, "is_staff", False):
        raise PermissionDenied("You can only delete your own replies.")
    reply.delete()
```

### Permission Check Table

| Check | Pattern | Use For |
|---|---|---|
| Logged in | `@login_required` | Any authenticated user |
| Staff | `getattr(user, "is_staff", False)` | Admin endpoints |
| Superuser | `getattr(user, "is_superuser", False)` | Dangerous operations |
| Owner | `.get(pk=pk, user=request.user)` | User's own content |
| Owner OR Staff | Owner check with staff fallback | Edit/delete with admin override |
| Permission | `user.has_perm("app.permission")` | Granular permissions |

## Anti-Patterns
- `request.user.is_staff` without `getattr` — crashes on `AnonymousUser`
- Trusting user-supplied PK without ownership check — IDOR vulnerability
- Permission checks only in templates — always enforce in views/services
- Returning 200 with error message instead of 403 — use proper HTTP status
- Checking permissions after performing the action — check BEFORE

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Auth Decorators](https://docs.djangoproject.com/en/5.2/topics/auth/default/#the-login-required-decorator)
