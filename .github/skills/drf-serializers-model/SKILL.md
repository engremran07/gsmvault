---
name: drf-serializers-model
description: "ModelSerializer patterns: fields, read_only, write_only, validation. Use when: creating DRF serializers from Django models, defining API schemas, field-level validation."
---

# DRF ModelSerializer Patterns

## When to Use
- Creating API serializer from an existing Django model
- Defining read-only/write-only fields for API responses and requests
- Adding field-level or object-level validation to serializer

## Rules
- Always use `ModelSerializer` over plain `Serializer` when backed by a model
- Always list `fields` explicitly — NEVER use `fields = "__all__"`
- `id` and timestamps go in `read_only_fields`
- Sensitive write fields (password) use `write_only=True`
- Business logic belongs in `services.py` — NOT in `create()`/`update()`
- Serializer file: `apps/<app>/api.py` (co-located with viewsets)

## Patterns

### Basic ModelSerializer
```python
from rest_framework import serializers
from .models import Firmware

class FirmwareSerializer(serializers.ModelSerializer):
    class Meta:
        model = Firmware
        fields = [
            "id", "name", "version", "file_size",
            "brand", "model", "status", "created_at",
        ]
        read_only_fields = ["id", "file_size", "status", "created_at"]
```

### Write-Only Fields (e.g., Password)
```python
class UserCreateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ["id", "email", "username", "password", "date_joined"]
        read_only_fields = ["id", "date_joined"]

    def create(self, validated_data: dict) -> User:
        # Delegate to service layer
        from .services import create_user
        return create_user(**validated_data)
```

### Field-Level Validation
```python
class FirmwareUploadSerializer(serializers.ModelSerializer):
    class Meta:
        model = Firmware
        fields = ["id", "name", "version", "file"]
        read_only_fields = ["id"]

    def validate_version(self, value: str) -> str:
        import re
        if not re.match(r"^\d+\.\d+\.\d+$", value):
            raise serializers.ValidationError("Version must be semver (e.g., 1.2.3).")
        return value

    def validate_file(self, value):
        max_size = 500 * 1024 * 1024  # 500 MB
        if value.size > max_size:
            raise serializers.ValidationError("File exceeds 500 MB limit.")
        return value
```

### Object-Level Validation (Cross-Field)
```python
class CampaignSerializer(serializers.ModelSerializer):
    class Meta:
        model = Campaign
        fields = ["id", "name", "start_at", "end_at", "budget", "status"]
        read_only_fields = ["id", "status"]

    def validate(self, data: dict) -> dict:
        if data.get("end_at") and data.get("start_at"):
            if data["end_at"] <= data["start_at"]:
                raise serializers.ValidationError(
                    {"end_at": "End date must be after start date."}
                )
        return data
```

### SerializerMethodField for Computed Values
```python
class DeviceSerializer(serializers.ModelSerializer):
    trust_label = serializers.SerializerMethodField()

    class Meta:
        model = Device
        fields = ["id", "name", "os", "trust_score", "trust_label"]
        read_only_fields = ["id", "trust_score", "trust_label"]

    def get_trust_label(self, obj: Device) -> str:
        if obj.trust_score >= 80:
            return "trusted"
        if obj.trust_score >= 50:
            return "moderate"
        return "untrusted"
```

## Anti-Patterns
- `fields = "__all__"` — exposes internal fields, security risk
- Logic in `create()`/`update()` — use `services.py` instead
- Missing `read_only_fields` on `id`, timestamps — clients shouldn't set these
- Bare `serializers.Serializer` when a model exists — loses automatic field mapping
- Returning raw dicts from views — always serialize through DRF

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [DRF ModelSerializer docs](https://www.django-rest-framework.org/api-guide/serializers/#modelserializer)
- Skill: `api-design` — full API endpoint wiring
