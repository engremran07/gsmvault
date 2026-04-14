---
paths: ["**/*.py"]
---

# Pyright Strict Mode Compliance

All Python files MUST pass Pyright/Pylance type checking with zero errors. Pyright is the
authoritative type checker; mypy is secondary.

## Required Type Annotations

| Element | Requirement | Example |
|---------|------------|---------|
| Function parameters | ALL public functions | `def create_user(email: str, name: str) -> User:` |
| Return types | ALL public functions | `-> QuerySet[Firmware]` |
| Class attributes | Public typed attributes | `name: str` |
| Module-level constants | Typed constants | `MAX_RETRIES: int = 3` |
| `get_queryset()` | Annotated return type | `def get_queryset(self) -> QuerySet[MyModel]:` |
| `ModelAdmin` | Generic type parameter | `class MyAdmin(admin.ModelAdmin[MyModel]):` |

## Type Ignore Rules

### REQUIRED format (always specify error code):
```python
# type: ignore[attr-defined]     — Django reverse FK managers
# type: ignore[import-untyped]   — Libraries without stubs
# type: ignore[union-attr]       — Optional attribute access
# type: ignore[override]         — Intentional signature override
# type: ignore[assignment]       — Dynamic assignment patterns
# type: ignore[misc]             — Only when no specific code applies
```

### FORBIDDEN:
```python
# type: ignore           — ❌ Blanket ignore without error code
# type: ignore[no-any]   — ❌ Unless genuinely unavoidable
# pyright: ignore         — ❌ Use # type: ignore[code] instead
```

## Import Resolution

| Pattern | Action |
|---------|--------|
| Missing stubs for django | Install `django-stubs` |
| Missing stubs for DRF | Install `djangorestframework-stubs` |
| Missing stubs for requests | Install `types-requests` |
| Missing stubs for redis | Install `types-redis` |
| Import from dissolved app | **FORBIDDEN** — import from target app |
| Circular import | Use `TYPE_CHECKING` block for type-only imports |
| Unresolved third-party import | Add `# type: ignore[import-untyped]` with comment |

## Common Django Patterns

### Reverse FK managers
```python
# Django creates reverse FK managers dynamically; Pyright cannot resolve them
brand.firmwares.all()  # type: ignore[attr-defined]  # reverse FK: Firmware.brand
```

### QuerySet narrowing
```python
from __future__ import annotations
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from apps.firmwares.models import Firmware

def get_firmware(pk: int) -> Firmware | None:
    from apps.firmwares.models import Firmware
    return Firmware.objects.filter(pk=pk).first()
```

### ModelAdmin typing
```python
from django.contrib import admin
from django.db.models import QuerySet

class FirmwareAdmin(admin.ModelAdmin["Firmware"]):
    def get_queryset(self, request: HttpRequest) -> QuerySet["Firmware"]:
        return super().get_queryset(request)
```

## Pyrightconfig.json Settings

The project `pyrightconfig.json` is the source of truth. Key settings:
- `typeCheckingMode`: Must be at least `"basic"` (targeting `"standard"`)
- `reportMissingImports`: `true`
- `reportMissingTypeStubs`: `"warning"`
- `reportUnusedImport`: `true`
- `reportUnusedVariable`: `true`
- `pythonVersion`: `"3.12"`
- `pythonPlatform`: `"All"`

## Zero Tolerance

- Zero Pyright errors in `apps/` directory
- Zero Pylance errors in VS Code Problems tab
- All new code must include type annotations
- All `# type: ignore` must have error codes
- All stubs must be installed via `requirements.txt`
