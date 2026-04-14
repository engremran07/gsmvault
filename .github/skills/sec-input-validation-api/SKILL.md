---
name: sec-input-validation-api
description: "API input validation: DRF serializers, field validators. Use when: validating API request data, custom serializer validation."
---

# API Input Validation

## When to Use

- Validating API request payloads
- Adding custom serializer validators
- Sanitizing API input before processing

## Rules

| Layer | Validator | Purpose |
|-------|-----------|---------|
| Field | `serializers.CharField(max_length=...)` | Field constraints |
| Field method | `validate_<field>()` | Custom field validation |
| Object | `validate()` | Cross-field validation |
| Model | `validators=[...]` | Model-level constraints |

## Patterns

### Serializer Field Validation
```python
from rest_framework import serializers

class FirmwareSerializer(serializers.ModelSerializer):
    name = serializers.CharField(max_length=200, min_length=3)
    description = serializers.CharField(max_length=5000, allow_blank=True)
    version = serializers.RegexField(r"^\d+\.\d+(\.\d+)?$")

    class Meta:
        model = Firmware
        fields = ["name", "description", "version", "brand", "model"]

    def validate_name(self, value: str) -> str:
        if "<" in value or ">" in value:
            raise serializers.ValidationError("HTML tags not allowed.")
        return value.strip()

    def validate(self, attrs: dict) -> dict:
        if attrs.get("brand") and not attrs.get("model"):
            raise serializers.ValidationError(
                {"model": "Model is required when brand is specified."}
            )
        return attrs
```

### Custom Validators
```python
from rest_framework.validators import UniqueTogetherValidator

class FirmwareSerializer(serializers.ModelSerializer):
    class Meta:
        model = Firmware
        fields = ["name", "version", "brand", "model"]
        validators = [
            UniqueTogetherValidator(
                queryset=Firmware.objects.all(),
                fields=["brand", "model", "version"],
                message="This firmware version already exists for this device.",
            )
        ]
```

### Nested Input Validation
```python
class BulkFirmwareSerializer(serializers.Serializer):
    firmwares = FirmwareSerializer(many=True, max_length=50)

    def validate_firmwares(self, value):
        if len(value) > 50:
            raise serializers.ValidationError("Maximum 50 items per batch.")
        return value
```

### View Usage
```python
class FirmwareCreateView(APIView):
    def post(self, request):
        serializer = FirmwareSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)  # Auto 400 on failure
        serializer.save(uploaded_by=request.user)
        return Response(serializer.data, status=201)
```

## Red Flags

- `request.data["field"]` without serializer validation
- Missing `max_length` on string fields
- No `raise_exception=True` on `is_valid()`
- Trusting `request.data` directly in ORM queries

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
