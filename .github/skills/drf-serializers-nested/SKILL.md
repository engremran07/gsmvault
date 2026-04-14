---
name: drf-serializers-nested
description: "Nested serializer patterns for related objects. Use when: including FK/M2M related data in API responses, embedding child objects in parent serializer output."
---

# DRF Nested Serializers

## When to Use
- API response needs related objects inline (e.g., firmware with its brand)
- Replacing FK integer IDs with full object representations
- Embedding child collections (e.g., topic with its replies)

## Rules
- Nested serializers are **read-only by default** — see `drf-serializers-writable-nested` for writes
- Use `select_related()` / `prefetch_related()` in the viewset queryset to avoid N+1
- Keep nesting to 2 levels max — deeper nesting signals a design problem
- Use `many=True` for reverse FK / M2M collections

## Patterns

### FK Nested Read
```python
from rest_framework import serializers
from .models import Firmware, Brand

class BrandMinimalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Brand
        fields = ["id", "name", "slug"]

class FirmwareDetailSerializer(serializers.ModelSerializer):
    brand = BrandMinimalSerializer(read_only=True)

    class Meta:
        model = Firmware
        fields = ["id", "name", "version", "brand", "created_at"]
        read_only_fields = ["id", "created_at"]
```

### Reverse FK Collection
```python
class ReplySerializer(serializers.ModelSerializer):
    class Meta:
        model = ForumReply
        fields = ["id", "body", "author", "created_at"]

class TopicDetailSerializer(serializers.ModelSerializer):
    replies = ReplySerializer(many=True, read_only=True, source="forumreply_set")

    class Meta:
        model = ForumTopic
        fields = ["id", "title", "body", "replies", "created_at"]
```

### Conditional Nesting (List vs Detail)
```python
class FirmwareListSerializer(serializers.ModelSerializer):
    """List view — FK as ID only for performance."""
    class Meta:
        model = Firmware
        fields = ["id", "name", "version", "brand", "created_at"]

class FirmwareDetailSerializer(serializers.ModelSerializer):
    """Detail view — FK expanded to full object."""
    brand = BrandMinimalSerializer(read_only=True)
    model_info = ModelMinimalSerializer(read_only=True, source="model")

    class Meta:
        model = Firmware
        fields = ["id", "name", "version", "brand", "model_info", "created_at"]
```

### ViewSet Switching Serializer
```python
from rest_framework import viewsets

class FirmwareViewSet(viewsets.ModelViewSet):
    queryset = Firmware.objects.select_related("brand", "model").all()

    def get_serializer_class(self):
        if self.action == "list":
            return FirmwareListSerializer
        return FirmwareDetailSerializer
```

### M2M Nested
```python
class TagSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tag
        fields = ["id", "name", "slug"]

class PostSerializer(serializers.ModelSerializer):
    tags = TagSerializer(many=True, read_only=True)

    class Meta:
        model = Post
        fields = ["id", "title", "tags", "published_at"]
```

### StringRelatedField for Simple Display
```python
class FirmwareSerializer(serializers.ModelSerializer):
    brand = serializers.StringRelatedField()  # uses Brand.__str__()

    class Meta:
        model = Firmware
        fields = ["id", "name", "brand"]
```

## Anti-Patterns
- Nested serializer without `select_related` / `prefetch_related` — causes N+1 queries
- Nesting 3+ levels deep — flatten or use separate endpoints
- Using nested serializer for write operations without explicit `create()`/`update()`
- `depth = 2` on Meta — uncontrolled nesting, exposes unexpected fields

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-serializers-model` — base ModelSerializer patterns
- Skill: `drf-serializers-writable-nested` — nested create/update
