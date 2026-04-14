---
name: sec-file-upload-size
description: "File size limits: MAX_UPLOAD_SIZE, storage quotas. Use when: configuring upload size limits, preventing disk exhaustion."
---

# File Upload Size Limits

## When to Use

- Setting maximum file upload sizes
- Preventing disk exhaustion attacks
- Configuring per-tier upload quotas

## Rules

| Setting | Value | Purpose |
|---------|-------|---------|
| `DATA_UPLOAD_MAX_MEMORY_SIZE` | 10 MB | In-memory upload limit |
| `FILE_UPLOAD_MAX_MEMORY_SIZE` | 5 MB | Threshold for disk-based upload |
| Custom `MAX_FIRMWARE_SIZE` | 500 MB | Firmware file limit |
| Custom `MAX_IMAGE_SIZE` | 10 MB | Image upload limit |
| Custom `MAX_AVATAR_SIZE` | 2 MB | Avatar upload limit |

## Patterns

### Django Settings
```python
# settings.py
DATA_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024   # 10 MB
FILE_UPLOAD_MAX_MEMORY_SIZE = 5 * 1024 * 1024     # 5 MB
DATA_UPLOAD_MAX_NUMBER_FIELDS = 1000

# Custom limits
MAX_FIRMWARE_SIZE = 500 * 1024 * 1024   # 500 MB
MAX_IMAGE_SIZE = 10 * 1024 * 1024       # 10 MB
MAX_AVATAR_SIZE = 2 * 1024 * 1024       # 2 MB
```

### Validator Function
```python
from django.conf import settings
from django.core.exceptions import ValidationError

def validate_file_size(uploaded_file, max_bytes: int | None = None) -> None:
    limit = max_bytes or settings.MAX_FIRMWARE_SIZE
    if uploaded_file.size > limit:
        limit_mb = limit / (1024 * 1024)
        file_mb = uploaded_file.size / (1024 * 1024)
        raise ValidationError(
            f"File size {file_mb:.1f} MB exceeds limit of {limit_mb:.0f} MB."
        )
```

### Tier-Based Size Limits
```python
def get_upload_limit(user) -> int:
    """Return max upload size in bytes based on user tier."""
    from apps.devices.models import QuotaTier
    tier = QuotaTier.objects.filter(
        name=getattr(user, "subscription_tier", "free")
    ).first()
    if tier:
        return tier.max_upload_bytes
    return 100 * 1024 * 1024  # 100 MB default
```

### Nginx/Gunicorn Limits
```nginx
# nginx.conf — must match or exceed Django settings
client_max_body_size 512m;
client_body_timeout 300s;
```

```python
# gunicorn.conf.py
timeout = 300  # Allow time for large uploads
```

### Frontend Size Check (Pre-Upload)
```html
<input type="file" @change="
    if ($event.target.files[0]?.size > 500 * 1024 * 1024) {
        alert('File exceeds 500 MB limit');
        $event.target.value = '';
    }
">
```

## Red Flags

- No `DATA_UPLOAD_MAX_MEMORY_SIZE` set (Django default is 2.5 MB)
- No file size validation in service layer
- Nginx `client_max_body_size` not configured (default 1 MB)
- No per-tier upload limits

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
