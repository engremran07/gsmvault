---
name: sec-nosql-injection
description: "NoSQL injection prevention in JSONField queries. Use when: querying JSONField, filtering on JSON keys, user-supplied JSON paths."
---

# NoSQL Injection Prevention

## When to Use

- Querying `JSONField` with user-supplied keys or paths
- Building dynamic JSON lookups from request parameters
- Filtering on nested JSON data

## Rules

| Rule | Implementation |
|------|----------------|
| Never build JSON paths from user input | Allowlist valid paths |
| Use ORM JSON lookups | `__contains`, `__has_key`, `__0` |
| Validate JSON input | Deserialize and validate structure |
| No dynamic key interpolation | Static paths only in ORM queries |

## Patterns

### Safe JSONField Queries
```python
# SAFE: Static key lookup
Device.objects.filter(metadata__contains={"os": "android"})
Device.objects.filter(metadata__has_key="browser")
Device.objects.filter(metadata__os="android")

# SAFE: Nested static path
Device.objects.filter(metadata__screen__width__gte=1920)
```

### Dangerous Dynamic Key — Use Allowlist
```python
# FORBIDDEN: User controls the JSON path
field = request.GET.get("field")  # Could be "__password" or similar
Device.objects.filter(**{f"metadata__{field}": value})  # INJECTION RISK

# SAFE: Allowlist valid fields
ALLOWED_METADATA_FIELDS = {"os", "browser", "device_type", "screen_width"}

def filter_devices(request: HttpRequest) -> QuerySet:
    field = request.GET.get("field", "")
    value = request.GET.get("value", "")
    if field not in ALLOWED_METADATA_FIELDS:
        return Device.objects.none()
    return Device.objects.filter(**{f"metadata__{field}": value})
```

### Validating JSON Input
```python
from rest_framework import serializers

class MetadataFilterSerializer(serializers.Serializer):
    os = serializers.ChoiceField(choices=["android", "ios", "windows"], required=False)
    browser = serializers.CharField(max_length=50, required=False)

    def get_filters(self) -> dict:
        filters = {}
        for key, value in self.validated_data.items():
            if value:
                filters[f"metadata__{key}"] = value
        return filters
```

## Red Flags

- `**{f"metadata__{user_input}": value}` without allowlist
- User input used as JSON path segments
- `json.loads(request.body)` used directly in ORM filters
- Dynamic `__` path construction from request parameters

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
