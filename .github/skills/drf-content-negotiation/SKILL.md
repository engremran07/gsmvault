---
name: drf-content-negotiation
description: "Content negotiation: JSON, HTML, custom renderers. Use when: serving multiple response formats from same endpoint, adding CSV/PDF renderers, custom response formatting."
---

# DRF Content Negotiation

## When to Use
- Same endpoint serves JSON (API) and HTML (browser)
- Adding CSV, PDF, or XML response formats
- Custom response envelope or formatting

## Rules
- `JSONRenderer` is the default — always available
- `BrowsableAPIRenderer` only in development (disable in production)
- Custom renderers for CSV, PDF, or admin export features
- Content type negotiated via `Accept` header or `?format=json` query param

## Patterns

### Settings Configuration
```python
REST_FRAMEWORK = {
    "DEFAULT_RENDERER_CLASSES": [
        "rest_framework.renderers.JSONRenderer",
        # Enable browsable API in dev only:
        # "rest_framework.renderers.BrowsableAPIRenderer",
    ],
}
```

### Per-View Renderer Override
```python
from rest_framework.renderers import JSONRenderer, BrowsableAPIRenderer

class FirmwareViewSet(viewsets.ModelViewSet):
    renderer_classes = [JSONRenderer]  # JSON only

class DebugViewSet(viewsets.ModelViewSet):
    renderer_classes = [JSONRenderer, BrowsableAPIRenderer]  # dev-friendly
```

### Custom JSON Envelope Renderer
```python
from rest_framework.renderers import JSONRenderer

class EnvelopeRenderer(JSONRenderer):
    """Wraps all responses in {"data": ..., "meta": {...}}."""

    def render(self, data, accepted_media_type=None, renderer_context=None):
        response = renderer_context.get("response") if renderer_context else None
        envelope = {
            "data": data,
            "meta": {
                "status": response.status_code if response else 200,
            },
        }
        return super().render(envelope, accepted_media_type, renderer_context)
```

### CSV Renderer
```python
import csv
import io
from rest_framework.renderers import BaseRenderer

class CSVRenderer(BaseRenderer):
    media_type = "text/csv"
    format = "csv"
    charset = "utf-8"

    def render(self, data, accepted_media_type=None, renderer_context=None):
        if not data:
            return ""
        # Handle paginated responses
        results = data.get("results", data) if isinstance(data, dict) else data
        if not isinstance(results, list) or not results:
            return ""

        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=results[0].keys())
        writer.writeheader()
        writer.writerows(results)
        return output.getvalue()
```

### ViewSet with Multiple Formats
```python
class FirmwareViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Firmware.objects.all()
    serializer_class = FirmwareSerializer
    renderer_classes = [JSONRenderer, CSVRenderer]

    # GET /api/v1/firmwares/?format=csv
    # GET /api/v1/firmwares/ (Accept: text/csv)
```

### Plain Text Renderer (Health Check)
```python
from rest_framework.renderers import BaseRenderer

class PlainTextRenderer(BaseRenderer):
    media_type = "text/plain"
    format = "txt"

    def render(self, data, accepted_media_type=None, renderer_context=None):
        return str(data)

class HealthCheckView(APIView):
    renderer_classes = [PlainTextRenderer, JSONRenderer]
    permission_classes = []

    def get(self, request):
        return Response("OK")
```

### Content Negotiation via Query Param
```
GET /api/v1/firmwares/               → JSON (default)
GET /api/v1/firmwares/?format=csv    → CSV
GET /api/v1/firmwares/?format=json   → JSON (explicit)
```

## Anti-Patterns
- `BrowsableAPIRenderer` in production → performance overhead, info disclosure
- Custom renderer without `charset` → encoding issues
- CSV renderer that doesn't handle pagination envelope → broken output
- No `format` attribute on renderer → `?format=` param doesn't work

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `drf-versioning-header` — Accept header versioning
- Skill: `services-csv-export` — CSV export patterns
