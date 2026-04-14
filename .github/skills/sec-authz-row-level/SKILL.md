---
name: sec-authz-row-level
description: "Row-level security: filtering by user, tenant isolation. Use when: multi-tenant data isolation, user-scoped querysets."
---

# Row-Level Security

## When to Use

- Ensuring users only see their own data in list views
- Multi-tenant data isolation
- Default queryset scoping in managers

## Rules

| Rule | Implementation |
|------|----------------|
| Manager-level scoping | Custom manager filters by user |
| View-level filtering | Always add user filter in `get_queryset()` |
| Admin exception | Staff can see all via separate admin queryset |
| No leakage in templates | Related objects also filtered |

## Patterns

### Custom Manager for Row-Level Filtering
```python
from django.db import models

class UserScopedManager(models.Manager):
    def for_user(self, user):
        return self.get_queryset().filter(user=user)

class DownloadToken(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    firmware = models.ForeignKey("firmwares.Firmware", on_delete=models.CASCADE)
    status = models.CharField(max_length=20)

    objects = UserScopedManager()
```

### View with Row-Level Filtering
```python
class MyDownloadsView(LoginRequiredMixin, ListView):
    template_name = "firmwares/my_downloads.html"
    paginate_by = 20

    def get_queryset(self):
        return DownloadToken.objects.for_user(
            self.request.user
        ).select_related("firmware").order_by("-created_at")
```

### DRF ViewSet Scoping
```python
class WalletTransactionViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Row-level: users only see their own transactions
        return Transaction.objects.filter(
            wallet__user=self.request.user
        ).select_related("wallet").order_by("-created_at")
```

### Admin Override
```python
class DownloadTokenAdmin(admin.ModelAdmin["DownloadToken"]):
    def get_queryset(self, request):
        # Admin sees all rows — no user filtering
        return super().get_queryset(request)
```

### Related Object Scoping
```python
def user_firmware_detail(request: HttpRequest, pk: int) -> HttpResponse:
    firmware = get_object_or_404(Firmware, pk=pk)
    # Filter related downloads to current user only
    user_downloads = firmware.download_tokens.filter(user=request.user)
    return render(request, "firmwares/detail.html", {
        "firmware": firmware,
        "my_downloads": user_downloads,
    })
```

## Red Flags

- `Model.objects.all()` in user-facing views without user filter
- Related objects (`firmware.comments.all()`) shown without user context
- Missing `get_queryset()` override in DRF ViewSets
- Admin views accidentally using user-scoped manager

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
