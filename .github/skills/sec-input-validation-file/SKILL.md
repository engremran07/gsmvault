---
name: sec-input-validation-file
description: "File upload validation: MIME type, extension, file size. Use when: accepting file uploads, firmware uploads, image uploads."
---

# File Upload Validation

## When to Use

- Accepting any file upload from users
- Validating firmware file uploads
- Processing image/avatar uploads

## Rules

| Check | Method | Layer |
|-------|--------|-------|
| Extension | Allowlist check | Form/Serializer |
| MIME type | `python-magic` or content sniffing | Service layer |
| File size | Compare against max limit | Form/Serializer |
| Magic bytes | Read first bytes, verify signature | Service layer |
| Filename | Sanitize for path traversal | Service layer |

## Patterns

### Complete File Validation
```python
import os
from django.core.exceptions import ValidationError

ALLOWED_EXTENSIONS = {".zip", ".rar", ".7z", ".bin", ".img", ".tar.gz"}
MAX_FILE_SIZE = 500 * 1024 * 1024  # 500 MB

def validate_firmware_upload(uploaded_file) -> None:
    """Validate firmware file — call in service layer."""
    # 1. Check file size
    if uploaded_file.size > MAX_FILE_SIZE:
        raise ValidationError(
            f"File too large: {uploaded_file.size / (1024*1024):.1f} MB. "
            f"Max: {MAX_FILE_SIZE / (1024*1024):.0f} MB."
        )
    # 2. Check extension (allowlist)
    _, ext = os.path.splitext(uploaded_file.name.lower())
    if ext not in ALLOWED_EXTENSIONS:
        raise ValidationError(f"File type '{ext}' is not allowed.")
    # 3. Check MIME type
    import magic
    mime = magic.from_buffer(uploaded_file.read(2048), mime=True)
    uploaded_file.seek(0)
    allowed_mimes = {
        "application/zip", "application/x-rar-compressed",
        "application/x-7z-compressed", "application/octet-stream",
        "application/gzip",
    }
    if mime not in allowed_mimes:
        raise ValidationError(f"Invalid file content type: {mime}")
    # 4. Sanitize filename
    safe_name = os.path.basename(uploaded_file.name)
    if ".." in safe_name or "/" in safe_name or "\\" in safe_name:
        raise ValidationError("Invalid filename.")
```

### Form-Level Validation
```python
class FirmwareUploadForm(forms.Form):
    file = forms.FileField()

    def clean_file(self):
        f = self.cleaned_data["file"]
        validate_firmware_upload(f)
        return f
```

### DRF File Validation
```python
class FirmwareUploadSerializer(serializers.Serializer):
    file = serializers.FileField()

    def validate_file(self, value):
        validate_firmware_upload(value)
        return value
```

## Red Flags

- No file size limit — allows disk exhaustion attacks
- Extension-only validation without MIME check — trivially bypassed
- Using `uploaded_file.content_type` (client-supplied, untrustworthy)
- No filename sanitization — path traversal risk
- Storing uploaded files in web-accessible directories

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
