---
name: drf-serializers-writable-nested
description: "Writable nested serializers for create/update with related objects. Use when: API endpoints need to create/update parent and child objects in a single request."
---

# DRF Writable Nested Serializers

## When to Use
- Single API call must create parent + children (e.g., order + line items)
- Update endpoint modifies parent and replaces/adds child records
- Bulk child creation through a parent endpoint

## Rules
- Override `create()` and `update()` explicitly — DRF does NOT auto-handle nested writes
- Wrap in `@transaction.atomic` to ensure data consistency
- Delegate complex logic to `services.py` — serializer handles data shaping only
- Validate children in serializer, persist in service layer
- Always handle the M2M / reverse FK `set()` / `clear()` carefully

## Patterns

### Writable Nested Create
```python
from django.db import transaction
from rest_framework import serializers
from .models import Order, OrderItem

class OrderItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderItem
        fields = ["id", "product", "quantity", "price"]
        read_only_fields = ["id", "price"]

class OrderCreateSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True)

    class Meta:
        model = Order
        fields = ["id", "customer_note", "items", "created_at"]
        read_only_fields = ["id", "created_at"]

    def validate_items(self, value: list[dict]) -> list[dict]:
        if not value:
            raise serializers.ValidationError("Order must have at least one item.")
        return value

    @transaction.atomic
    def create(self, validated_data: dict) -> Order:
        items_data = validated_data.pop("items")
        order = Order.objects.create(**validated_data)
        for item_data in items_data:
            OrderItem.objects.create(order=order, **item_data)
        return order
```

### Writable Nested Update (Replace Children)
```python
class OrderUpdateSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True)

    class Meta:
        model = Order
        fields = ["id", "customer_note", "items"]
        read_only_fields = ["id"]

    @transaction.atomic
    def update(self, instance: Order, validated_data: dict) -> Order:
        items_data = validated_data.pop("items", None)
        # Update parent fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        # Replace children
        if items_data is not None:
            instance.items.all().delete()
            for item_data in items_data:
                OrderItem.objects.create(order=instance, **item_data)
        return instance
```

### M2M Writable (Tags)
```python
class PostSerializer(serializers.ModelSerializer):
    tag_ids = serializers.PrimaryKeyRelatedField(
        queryset=Tag.objects.all(),
        many=True,
        write_only=True,
        source="tags",
    )
    tags = TagSerializer(many=True, read_only=True)

    class Meta:
        model = Post
        fields = ["id", "title", "body", "tags", "tag_ids"]
        read_only_fields = ["id"]

    @transaction.atomic
    def create(self, validated_data: dict) -> Post:
        tags = validated_data.pop("tags", [])
        post = Post.objects.create(**validated_data)
        post.tags.set(tags)
        return post

    @transaction.atomic
    def update(self, instance: Post, validated_data: dict) -> Post:
        tags = validated_data.pop("tags", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if tags is not None:
            instance.tags.set(tags)
        return instance
```

### Delegating to Service Layer
```python
class FirmwareUploadSerializer(serializers.ModelSerializer):
    """Complex create → delegate to service."""
    class Meta:
        model = Firmware
        fields = ["id", "name", "version", "file", "brand"]
        read_only_fields = ["id"]

    def create(self, validated_data: dict) -> Firmware:
        from .services import create_firmware
        user = self.context["request"].user
        return create_firmware(uploaded_by=user, **validated_data)
```

## Anti-Patterns
- Relying on DRF's default nested write (it raises `AssertionError`)
- `create()` without `@transaction.atomic` — partial writes on failure
- Updating children without clearing old ones — stale children persist
- Heavy business logic in `create()`/`update()` — belongs in `services.py`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-serializers-nested` — read-only nested patterns
- Skill: `services-transaction-atomic` — transaction safety
