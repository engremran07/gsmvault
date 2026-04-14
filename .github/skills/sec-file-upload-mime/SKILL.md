---
name: sec-file-upload-mime
description: "MIME type validation: python-magic, content sniffing prevention. Use when: validating uploaded file content types."
---

# MIME Type Validation

## When to Use

- Validating that uploaded file content matches claimed type
- Preventing content-type spoofing attacks
- Configuring X-Content-Type-Options header

## Rules

| Rule | Implementation |
|------|----------------|
| Never trust `content_type` | Client-supplied, always check with `python-magic` |
| Server-side detection | Use `magic.from_buffer()` for real MIME type |
| X-Content-Type-Options | Set `nosniff` header to prevent browser sniffing |
| Allowlist MIME types | Reject unknown types |

## Patterns

### MIME Detection with python-magic
```python
import magic

def detect_mime_type(uploaded_file) -> str:
    """Detect actual MIME type from file content."""
    chunk = uploaded_file.read(2048)
    uploaded_file.seek(0)  # Reset for further processing
    return magic.from_buffer(chunk, mime=True)

def validate_image_upload(uploaded_file) -> None:
    mime = detect_mime_type(uploaded_file)
    allowed = {"image/jpeg", "image/png", "image/webp", "image/gif"}
    if mime not in allowed:
        raise ValidationError(
            f"Invalid image type: {mime}. Allowed: {', '.join(allowed)}"
        )
```

### MIME + Extension Cross-Check
```python
MIME_EXTENSION_MAP = {
    "image/jpeg": {".jpg", ".jpeg"},
    "image/png": {".png"},
    "image/webp": {".webp"},
    "application/zip": {".zip"},
    "application/pdf": {".pdf"},
}

def validate_mime_extension(uploaded_file) -> None:
    mime = detect_mime_type(uploaded_file)
    ext = os.path.splitext(uploaded_file.name.lower())[1]
    valid_exts = MIME_EXTENSION_MAP.get(mime, set())
    if ext not in valid_exts:
        raise ValidationError(
            f"Extension '{ext}' does not match content type '{mime}'."
        )
```

### Content-Type-Options Header
```python
# settings.py
SECURE_CONTENT_TYPE_NOSNIFF = True  # Sets X-Content-Type-Options: nosniff
```

### Serving Files with Correct MIME
```python
from django.http import FileResponse

def serve_download(request, pk):
    firmware = get_object_or_404(Firmware, pk=pk)
    response = FileResponse(firmware.file.open("rb"))
    response["Content-Type"] = "application/octet-stream"
    response["X-Content-Type-Options"] = "nosniff"
    return response
```

## Red Flags

- Using `uploaded_file.content_type` directly (client-controlled)
- Missing `python-magic` dependency for server-side detection
- No MIME allowlist — accepting any file type
- `SECURE_CONTENT_TYPE_NOSNIFF = False`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
