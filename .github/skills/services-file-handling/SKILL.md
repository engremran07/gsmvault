---
name: services-file-handling
description: "File upload/download handling: validation, storage, serving. Use when: processing file uploads, validating MIME types, serving file downloads, managing file storage."
---

# File Handling Patterns

## When to Use
- Processing user file uploads (firmware files, avatars, attachments)
- Validating file type, size, and content
- Serving protected file downloads
- Managing file storage (local or GCS via `apps.storage`)

## Rules
- Validate MIME type, file extension, AND file size in the service layer before storage
- Never trust client-provided `content_type` — verify with magic bytes
- Max file sizes enforced per upload type (firmware: 4GB, avatar: 5MB, attachment: 20MB)
- Use `apps.storage` for all file storage — never write directly to filesystem
- Protected downloads: generate signed URLs or stream via Django with auth check

## Patterns

### File Upload Validation
```python
import logging
import mimetypes
from django.core.files.uploadedfile import UploadedFile

logger = logging.getLogger(__name__)

ALLOWED_FIRMWARE_EXTENSIONS = {".zip", ".rar", ".7z", ".bin", ".img", ".tar.gz"}
MAX_FIRMWARE_SIZE = 4 * 1024 * 1024 * 1024  # 4GB

class FileValidationError(Exception):
    pass

def validate_firmware_upload(file: UploadedFile) -> None:
    """Validate firmware file before storage."""
    # Check file size
    if file.size and file.size > MAX_FIRMWARE_SIZE:
        raise FileValidationError(f"File too large: {file.size} bytes (max {MAX_FIRMWARE_SIZE})")
    # Check extension
    ext = "." + file.name.rsplit(".", 1)[-1].lower() if "." in file.name else ""
    if ext not in ALLOWED_FIRMWARE_EXTENSIONS:
        raise FileValidationError(f"Invalid extension: {ext}")
    # Check MIME type
    mime_type = mimetypes.guess_type(file.name)[0]
    if mime_type and not mime_type.startswith(("application/", "binary/")):
        raise FileValidationError(f"Invalid MIME type: {mime_type}")
```

### Upload Service
```python
from django.db import transaction

@transaction.atomic
def upload_firmware_file(
    *, user_id: int, file: UploadedFile, firmware_id: int
) -> str:
    """Validate and store firmware file."""
    validate_firmware_upload(file)
    firmware = Firmware.objects.select_for_update().get(pk=firmware_id)
    firmware.file = file
    firmware.file_size = file.size
    firmware.original_filename = file.name
    firmware.save(update_fields=["file", "file_size", "original_filename"])
    logger.info("Firmware file uploaded: %s by user %s", firmware_id, user_id)
    return firmware.file.name
```

### Protected File Download
```python
from django.http import FileResponse, Http404

def serve_firmware_download(*, firmware_id: int, user_id: int) -> FileResponse:
    """Serve firmware file with access control."""
    firmware = Firmware.objects.get(pk=firmware_id, is_active=True)
    # Access check via download token or quota
    if not firmware.file:
        raise Http404("File not found")
    response = FileResponse(
        firmware.file.open("rb"),
        content_type="application/octet-stream",
    )
    response["Content-Disposition"] = f'attachment; filename="{firmware.original_filename}"'
    response["Content-Length"] = firmware.file_size
    return response
```

### Streaming Large Files
```python
from django.http import StreamingHttpResponse

def stream_large_file(file_path: str, chunk_size: int = 8192):
    def file_iterator():
        with open(file_path, "rb") as f:
            while chunk := f.read(chunk_size):
                yield chunk
    response = StreamingHttpResponse(file_iterator(), content_type="application/octet-stream")
    response["Content-Disposition"] = f'attachment; filename="{file_path.split("/")[-1]}"'
    return response
```

## Anti-Patterns
- Trusting `file.content_type` from the client — always verify
- No file size limit — allows disk exhaustion attacks
- Storing uploaded files directly in code directories — use dedicated storage
- Serving files without authentication for protected content

## Red Flags
- File upload handler without size validation
- `open()` with user-supplied path — path traversal risk
- No MIME type validation on uploads

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
