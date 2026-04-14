---
name: drf-viewsets-custom
description: "Custom ViewSet actions: @action decorator, extra routes. Use when: adding non-CRUD endpoints to a ViewSet like approve, export, stats, toggle actions."
---

# DRF Custom ViewSet Actions

## When to Use
- Adding non-CRUD endpoints to an existing ViewSet (e.g., `/firmware/1/approve/`)
- Creating collection-level actions (e.g., `/firmware/stats/`)
- Need extra routes beyond list/create/retrieve/update/destroy

## Rules
- Use `@action` decorator on ViewSet methods
- `detail=True` → operates on a single object (`/resource/{pk}/action/`)
- `detail=False` → operates on collection (`/resource/action/`)
- Custom actions auto-register with the router — no manual URL wiring
- Delegate logic to `services.py` — action methods stay thin

## Patterns

### Detail Action (Single Object)
```python
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response

class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.all()
    serializer_class = FirmwareSerializer

    @action(detail=True, methods=["post"], permission_classes=[IsAdminUser])
    def approve(self, request, pk=None):
        firmware = self.get_object()
        from .services import approve_firmware
        approve_firmware(firmware, approved_by=request.user)
        return Response({"status": "approved"})

    @action(detail=True, methods=["post"])
    def toggle_active(self, request, pk=None):
        firmware = self.get_object()
        firmware.is_active = not firmware.is_active
        firmware.save(update_fields=["is_active"])
        return Response({"is_active": firmware.is_active})
```

### Collection Action (List-Level)
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.all()

    @action(detail=False, methods=["get"])
    def stats(self, request):
        from django.db.models import Count, Sum
        stats = Firmware.objects.aggregate(
            total=Count("id"),
            total_size=Sum("file_size"),
        )
        return Response(stats)

    @action(detail=False, methods=["get"])
    def recent(self, request):
        recent = self.get_queryset().order_by("-created_at")[:10]
        serializer = self.get_serializer(recent, many=True)
        return Response(serializer.data)
```

### Custom Serializer per Action
```python
class TopicViewSet(viewsets.ModelViewSet):
    queryset = ForumTopic.objects.all()

    def get_serializer_class(self):
        if self.action == "list":
            return TopicListSerializer
        if self.action == "lock":
            return TopicLockSerializer
        return TopicDetailSerializer

    @action(detail=True, methods=["post"], permission_classes=[IsAdminUser])
    def lock(self, request, pk=None):
        topic = self.get_object()
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        topic.is_locked = True
        topic.lock_reason = serializer.validated_data.get("reason", "")
        topic.save(update_fields=["is_locked", "lock_reason"])
        return Response({"status": "locked"})
```

### Action with Custom URL Path
```python
@action(detail=True, methods=["get"], url_path="download-link", url_name="download-link")
def download_link(self, request, pk=None):
    firmware = self.get_object()
    from .services import create_download_token
    token = create_download_token(firmware=firmware, user=request.user)
    return Response({"url": token.url, "expires_at": token.expires_at})
```

### Bulk Action
```python
@action(detail=False, methods=["post"], permission_classes=[IsAdminUser])
def bulk_approve(self, request):
    ids = request.data.get("ids", [])
    if not ids:
        return Response(
            {"error": "No IDs provided", "code": "MISSING_IDS"},
            status=status.HTTP_400_BAD_REQUEST,
        )
    updated = Firmware.objects.filter(id__in=ids, status="pending").update(
        status="approved"
    )
    return Response({"approved_count": updated})
```

## Anti-Patterns
- Heavy logic inside `@action` methods — move to `services.py`
- Missing `permission_classes` on action — inherits ViewSet default (may be too permissive)
- Using manual URL patterns instead of `@action` — router does it automatically
- Forgetting `detail=True` vs `detail=False` — wrong URL structure

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-viewsets-model` — base ViewSet patterns
- Skill: `drf-permissions-object` — object permission on actions
