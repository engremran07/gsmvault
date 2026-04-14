---
name: sec-file-upload-path
description: "Path traversal prevention in file uploads. Use when: storing uploaded files, generating file paths from user input."
---

# Path Traversal Prevention

## When to Use

- Storing uploaded files to disk
- Generating file paths from user input
- Serving files by user-supplied filename

## Rules

| Rule | Implementation |
|------|----------------|
| Sanitize filename | `os.path.basename()` — strip directory components |
| No `..` sequences | Reject or strip before path construction |
| Absolute path check | Ensure result stays within upload directory |
| UUID filenames | Replace user filename with UUID to eliminate risk |

## Patterns

### Filename Sanitization
```python
import os
import uuid
from django.utils.text import slugify

def sanitize_filename(filename: str) -> str:
    """Remove path traversal components from filename."""
    # Strip directory components
    safe = os.path.basename(filename)
    # Reject dangerous patterns
    if ".." in safe or "\x00" in safe:
        raise ValidationError("Invalid filename.")
    # Remove path separators that survived basename
    safe = safe.replace("/", "").replace("\\", "")
    if not safe:
        raise ValidationError("Empty filename.")
    return safe

def generate_safe_path(uploaded_file, prefix: str = "uploads") -> str:
    """Generate a safe storage path using UUID."""
    ext = os.path.splitext(uploaded_file.name)[1].lower()
    safe_ext = ext if ext in {".zip", ".rar", ".7z", ".bin", ".img", ".png", ".jpg"} else ""
    return f"{prefix}/{uuid.uuid4().hex}{safe_ext}"
```

### Django Upload Path
```python
def firmware_upload_path(instance, filename: str) -> str:
    """Generate upload path for firmware files."""
    safe_name = sanitize_filename(filename)
    return f"firmwares/{instance.brand.slug}/{uuid.uuid4().hex}_{slugify(safe_name)}"

class Firmware(models.Model):
    file = models.FileField(upload_to=firmware_upload_path)
```

### Serving Files Safely
```python
from django.http import FileResponse
from pathlib import Path

UPLOAD_ROOT = Path("/var/uploads")

def serve_file(request, filename: str):
    safe_name = sanitize_filename(filename)
    file_path = (UPLOAD_ROOT / safe_name).resolve()
    # Verify the resolved path is still within UPLOAD_ROOT
    if not str(file_path).startswith(str(UPLOAD_ROOT.resolve())):
        raise Http404("File not found.")
    if not file_path.exists():
        raise Http404("File not found.")
    return FileResponse(file_path.open("rb"))
```

### Symlink Protection
```python
def validate_no_symlink(file_path: Path) -> None:
    """Reject symlinks to prevent directory escape."""
    if file_path.is_symlink():
        raise ValidationError("Symbolic links are not allowed.")
```

## Red Flags

- `os.path.join(base, user_filename)` without sanitizing filename
- No `os.path.basename()` call on uploaded filenames
- Using user-supplied filenames directly in path construction
- Missing `.resolve()` + prefix check for symlink attacks
- Serving files from a web-accessible directory

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
