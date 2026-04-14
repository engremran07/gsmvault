---
name: drf-bulk-operations
description: "Bulk API operations: batch create/update/delete endpoints. Use when: client needs to create/update/delete multiple resources in a single API call."
---

# DRF Bulk Operations

## When to Use
- Admin batch operations (approve 50 items at once)
- Import endpoints (CSV upload → bulk create)
- Client-side bulk selection → single API call
- Reducing HTTP round-trips for batch mutations

## Rules
- Wrap bulk operations in `@transaction.atomic` — all-or-nothing
- Validate all items before persisting any
- Return per-item results (success/failure)
- Limit batch size to prevent DoS (max 100-500 items)
- Delegate to `services.py` for complex logic

## Patterns

### Bulk Create Endpoint
```python
from rest_framework import serializers, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import transaction

class FirmwareViewSet(viewsets.ModelViewSet):
    @action(detail=False, methods=["post"], url_path="bulk-create")
    @transaction.atomic
    def bulk_create(self, request):
        items = request.data.get("items", [])
        if not items:
            return Response(
                {"error": "No items provided", "code": "EMPTY_BATCH"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if len(items) > 100:
            return Response(
                {"error": "Max 100 items per batch", "code": "BATCH_TOO_LARGE"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = FirmwareSerializer(data=items, many=True)
        serializer.is_valid(raise_exception=True)
        instances = serializer.save()
        return Response(
            FirmwareSerializer(instances, many=True).data,
            status=status.HTTP_201_CREATED,
        )
```

### Bulk Update (PATCH)
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    @action(detail=False, methods=["patch"], url_path="bulk-update")
    @transaction.atomic
    def bulk_update(self, request):
        updates = request.data.get("items", [])
        if not updates or len(updates) > 100:
            return Response(
                {"error": "Provide 1-100 items", "code": "INVALID_BATCH"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        results = []
        for item in updates:
            pk = item.get("id")
            if not pk:
                results.append({"id": None, "status": "error", "error": "Missing ID"})
                continue
            try:
                instance = self.get_queryset().get(pk=pk)
                serializer = self.get_serializer(instance, data=item, partial=True)
                serializer.is_valid(raise_exception=True)
                serializer.save()
                results.append({"id": pk, "status": "updated"})
            except self.get_queryset().model.DoesNotExist:
                results.append({"id": pk, "status": "error", "error": "Not found"})

        return Response({"results": results})
```

### Bulk Delete
```python
class FirmwareViewSet(viewsets.ModelViewSet):
    @action(detail=False, methods=["post"], url_path="bulk-delete")
    @transaction.atomic
    def bulk_delete(self, request):
        ids = request.data.get("ids", [])
        if not ids:
            return Response(
                {"error": "No IDs provided", "code": "EMPTY_BATCH"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if len(ids) > 100:
            return Response(
                {"error": "Max 100 items", "code": "BATCH_TOO_LARGE"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        qs = self.get_queryset().filter(id__in=ids)
        deleted_count = qs.count()
        qs.delete()
        return Response({"deleted": deleted_count})
```

### Bulk Status Change (Admin)
```python
class IngestionJobViewSet(viewsets.ModelViewSet):
    @action(
        detail=False, methods=["post"],
        url_path="bulk-approve",
        permission_classes=[IsAdminUser],
    )
    @transaction.atomic
    def bulk_approve(self, request):
        ids = request.data.get("ids", [])
        updated = IngestionJob.objects.filter(
            id__in=ids, status="pending"
        ).update(status="approved")
        return Response({"approved": updated, "total": len(ids)})
```

### Request/Response Format
```json
// POST /api/v1/firmwares/bulk-create/
{
    "items": [
        {"name": "ROM_V1", "version": "1.0.0", "brand": 1},
        {"name": "ROM_V2", "version": "2.0.0", "brand": 1}
    ]
}

// Response
[
    {"id": 101, "name": "ROM_V1", "version": "1.0.0"},
    {"id": 102, "name": "ROM_V2", "version": "2.0.0"}
]
```

### Delegating to Service Layer
```python
@action(detail=False, methods=["post"], url_path="bulk-import")
def bulk_import(self, request):
    from .services import bulk_import_firmwares
    result = bulk_import_firmwares(
        items=request.data.get("items", []),
        imported_by=request.user,
    )
    return Response(result)
```

## Anti-Patterns
- No batch size limit → memory/DoS risk
- No `@transaction.atomic` → partial writes on failure
- Returning only count → client can't identify which items failed
- Heavy validation in the view → use serializer + service layer

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `services-bulk-operations` — service layer bulk patterns
- Skill: `drf-viewsets-custom` — @action decorator usage
