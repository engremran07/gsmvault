---
name: drf-file-upload
description: "File upload via API: multipart, chunk upload, validation. Use when: accepting file uploads through API, firmware file upload, avatar upload, attachment handling."
---

# DRF File Upload

## When to Use
- Accepting firmware file uploads via API
- Avatar/image upload endpoints
- Document/attachment upload
- Large file chunked upload

## Rules
- Use `multipart/form-data` content type for file uploads
- Validate file size, MIME type, and extension in the serializer
- Use `FileUploadParser` or `MultiPartParser` explicitly
- Large files: use chunked upload or streaming
- Delegate storage logic to `apps.storage` service layer
- Never trust client-provided filenames — sanitize them

## Patterns

### Basic File Upload Serializer
```python
from rest_framework import serializers

ALLOWED_EXTENSIONS = {".zip", ".rar", ".7z", ".bin", ".img", ".tar.gz"}
MAX_FILE_SIZE = 500 * 1024 * 1024  # 500 MB

class FirmwareUploadSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    version = serializers.CharField(max_length=50)
    brand = serializers.PrimaryKeyRelatedField(queryset=Brand.objects.all())
    file = serializers.FileField()

    def validate_file(self, value):
        # Size check
        if value.size > MAX_FILE_SIZE:
            raise serializers.ValidationError(
                f"File exceeds {MAX_FILE_SIZE // (1024*1024)} MB limit."
            )
        # Extension check
        import os
        ext = os.path.splitext(value.name)[1].lower()
        if ext not in ALLOWED_EXTENSIONS:
            raise serializers.ValidationError(
                f"Unsupported file type: {ext}. Allowed: {', '.join(ALLOWED_EXTENSIONS)}"
            )
        # MIME type check
        import mimetypes
        mime_type, _ = mimetypes.guess_type(value.name)
        if mime_type and mime_type.startswith("text/html"):
            raise serializers.ValidationError("HTML files are not allowed.")
        return value
```

### Upload ViewSet
```python
from rest_framework import viewsets, status, permissions
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response

class FirmwareUploadViewSet(viewsets.ViewSet):
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [permissions.IsAuthenticated]

    def create(self, request):
        serializer = FirmwareUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        from .services import handle_firmware_upload
        firmware = handle_firmware_upload(
            user=request.user,
            file=serializer.validated_data["file"],
            name=serializer.validated_data["name"],
            version=serializer.validated_data["version"],
            brand=serializer.validated_data["brand"],
        )
        return Response(
            FirmwareSerializer(firmware).data,
            status=status.HTTP_201_CREATED,
        )
```

### ModelSerializer with FileField
```python
class AvatarSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ["avatar"]

    def validate_avatar(self, value):
        max_size = 5 * 1024 * 1024  # 5 MB
        if value.size > max_size:
            raise serializers.ValidationError("Avatar must be under 5 MB.")
        allowed = {"image/jpeg", "image/png", "image/webp"}
        if value.content_type not in allowed:
            raise serializers.ValidationError("Only JPEG, PNG, and WebP allowed.")
        return value

class AvatarUploadView(APIView):
    parser_classes = [MultiPartParser]
    permission_classes = [permissions.IsAuthenticated]

    def put(self, request):
        profile = request.user.profile
        serializer = AvatarSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
```

### Chunked Upload (Large Files)
```python
from rest_framework.parsers import FileUploadParser

class ChunkedUploadView(APIView):
    parser_classes = [FileUploadParser]
    permission_classes = [permissions.IsAuthenticated]

    def put(self, request, filename):
        file_obj = request.data.get("file")
        chunk_number = int(request.headers.get("X-Chunk-Number", "0"))
        total_chunks = int(request.headers.get("X-Total-Chunks", "1"))

        from .services import handle_chunk_upload
        result = handle_chunk_upload(
            user=request.user,
            filename=filename,
            chunk=file_obj,
            chunk_number=chunk_number,
            total_chunks=total_chunks,
        )

        if result["complete"]:
            return Response({"status": "complete", "firmware_id": result["id"]})
        return Response({
            "status": "partial",
            "chunks_received": result["chunks_received"],
        })
```

### Multiple File Upload
```python
class MultiFileSerializer(serializers.Serializer):
    files = serializers.ListField(
        child=serializers.FileField(), max_length=10
    )

class MultiUploadView(APIView):
    parser_classes = [MultiPartParser]

    def post(self, request):
        serializer = MultiFileSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        results = []
        for f in serializer.validated_data["files"]:
            # Process each file
            results.append({"name": f.name, "size": f.size})
        return Response({"uploaded": results}, status=status.HTTP_201_CREATED)
```

### Client Upload Example
```bash
curl -X POST \
     -H "Authorization: Bearer <token>" \
     -F "name=Samsung_ROM" \
     -F "version=1.0.0" \
     -F "brand=1" \
     -F "file=@/path/to/firmware.zip" \
     https://api.example.com/api/v1/firmwares/upload/
```

## Anti-Patterns
- No file size limit → server memory exhaustion
- Trusting `content_type` from client → always verify server-side
- Storing uploads with original filename → path traversal risk
- Processing file in the view → delegate to service/Celery task
- No rate limiting on upload → abuse vector

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- Skill: `services-file-handling` — file storage patterns
- Skill: `drf-viewsets-custom` — custom action wiring
