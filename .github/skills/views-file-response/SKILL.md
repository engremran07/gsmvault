---
name: views-file-response
description: "File download responses: FileResponse, StreamingHttpResponse, content types. Use when: serving file downloads, streaming large files, setting content-disposition headers."
---

# File Download Responses

## When to Use
- Serving firmware file downloads
- Generating CSV/PDF exports
- Streaming large files without loading into memory
- Setting proper content-type and content-disposition headers

## Rules
- Use `FileResponse` for disk files — it handles Range requests and streaming
- Use `StreamingHttpResponse` for generated content (CSV exports, etc.)
- Always set `Content-Disposition` header with sanitized filename
- Validate download permissions BEFORE constructing the response
- Download token validation goes through `apps.firmwares.download_service`

## Patterns

### FileResponse for Disk Files
```python
from django.http import FileResponse
from pathlib import Path

@login_required
@require_GET
def download_firmware(request: HttpRequest, token: str) -> HttpResponse:
    # Validate token through service layer
    download_token = validate_download_token(token, request.user)
    if not download_token:
        raise Http404("Invalid or expired download token.")

    file_path = Path(download_token.firmware.file.path)
    if not file_path.exists():
        raise Http404("File not found.")

    response = FileResponse(
        open(file_path, "rb"),
        content_type="application/octet-stream",
        as_attachment=True,
        filename=download_token.firmware.safe_filename,
    )
    # Track download in service layer
    start_download_session(download_token, request)
    return response
```

### StreamingHttpResponse for CSV Export
```python
import csv
from django.http import StreamingHttpResponse

def export_firmwares_csv(request: HttpRequest) -> StreamingHttpResponse:
    """Stream CSV export — handles large datasets without memory issues."""

    def generate_rows():
        yield ["Name", "Brand", "Version", "Type", "Downloads", "Created"]
        for fw in Firmware.objects.filter(is_active=True).select_related("brand").iterator():
            yield [
                fw.name,
                fw.brand.name,
                fw.version,
                fw.firmware_type,
                str(fw.download_count),
                fw.created_at.isoformat(),
            ]

    def stream_csv():
        writer = csv.writer(Echo())
        for row in generate_rows():
            yield writer.writerow(row)

    response = StreamingHttpResponse(stream_csv(), content_type="text/csv")
    response["Content-Disposition"] = 'attachment; filename="firmwares_export.csv"'
    return response

class Echo:
    """Pseudo-buffer for StreamingHttpResponse CSV."""
    def write(self, value: str) -> str:
        return value
```

### Safe Filename Sanitization
```python
import re

def sanitize_filename(name: str) -> str:
    """Remove unsafe characters from filename."""
    safe = re.sub(r'[^\w\s\-.]', '', name)
    safe = re.sub(r'\s+', '_', safe)
    return safe[:255]  # Limit length

# On the model:
class Firmware(TimestampedModel):
    @property
    def safe_filename(self) -> str:
        return sanitize_filename(f"{self.name}_v{self.version}.zip")
```

### Content-Type Reference

| File Type | Content-Type |
|---|---|
| ZIP | `application/zip` |
| RAR | `application/x-rar-compressed` |
| 7z | `application/x-7z-compressed` |
| BIN | `application/octet-stream` |
| PDF | `application/pdf` |
| CSV | `text/csv` |
| JSON | `application/json` |
| Generic | `application/octet-stream` |

### Serving from Storage Backend
```python
from django.http import HttpResponseRedirect

@login_required
def download_from_storage(request: HttpRequest, pk: int) -> HttpResponse:
    firmware = get_object_or_404(Firmware, pk=pk)

    # For cloud storage (GCS/S3), redirect to signed URL
    if hasattr(firmware.file.storage, "url"):
        signed_url = firmware.file.storage.url(firmware.file.name, expire=300)
        return HttpResponseRedirect(signed_url)

    # For local storage, serve directly
    return FileResponse(firmware.file.open("rb"), as_attachment=True)
```

### X-Sendfile for Production (Nginx)
```python
def download_with_xsendfile(request: HttpRequest, pk: int) -> HttpResponse:
    firmware = get_object_or_404(Firmware, pk=pk)
    response = HttpResponse()
    response["Content-Type"] = "application/octet-stream"
    response["Content-Disposition"] = f'attachment; filename="{firmware.safe_filename}"'
    # Let Nginx handle the actual file serving
    response["X-Accel-Redirect"] = f"/protected-files/{firmware.file.name}"
    return response
```

## Anti-Patterns
- Loading entire file into memory — use `FileResponse` or streaming
- Unsanitized filenames in Content-Disposition — path traversal risk
- Missing permission check before serving file — always validate first
- Serving files from untrusted paths — validate file path is within allowed directory
- Not setting `Content-Type` — browser might execute instead of download

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django FileResponse](https://docs.djangoproject.com/en/5.2/ref/request-response/#fileresponse-objects)
- `apps/firmwares/download_service.py` — download gating service
