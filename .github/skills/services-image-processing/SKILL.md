---
name: services-image-processing
description: "Image processing: thumbnails, resizing, format conversion. Use when: generating thumbnails, resizing uploaded images, converting image formats, optimizing images."
---

# Image Processing Patterns

## When to Use
- Generating thumbnails for avatars, brand logos, firmware screenshots
- Resizing uploaded images to standard sizes
- Converting image formats (PNG → WebP for performance)
- Validating image dimensions and content

## Rules
- Use Pillow (`PIL`) for image processing — it's already in requirements
- Process images in service functions, never in views
- Validate image content (not just extension) before processing
- Generate multiple sizes on upload (thumbnail, medium, large)
- Use Celery for batch image processing
- Store processed images via `apps.storage` — never in temp directories

## Patterns

### Image Resize Service
```python
import io
import logging
from PIL import Image
from django.core.files.uploadedfile import InMemoryUploadedFile

logger = logging.getLogger(__name__)

THUMBNAIL_SIZES = {
    "thumb": (150, 150),
    "medium": (400, 400),
    "large": (800, 800),
}

def resize_image(
    *, image_file: InMemoryUploadedFile, max_size: tuple[int, int]
) -> io.BytesIO:
    """Resize image maintaining aspect ratio."""
    img = Image.open(image_file)
    img.thumbnail(max_size, Image.Resampling.LANCZOS)
    # Convert RGBA to RGB for JPEG
    if img.mode == "RGBA":
        img = img.convert("RGB")
    buffer = io.BytesIO()
    img.save(buffer, format="JPEG", quality=85, optimize=True)
    buffer.seek(0)
    return buffer
```

### Generate Multiple Thumbnails
```python
from django.core.files.base import ContentFile

def generate_thumbnails(
    *, image_file: InMemoryUploadedFile, base_name: str
) -> dict[str, str]:
    """Generate multiple thumbnail sizes, return storage paths."""
    paths = {}
    for size_name, dimensions in THUMBNAIL_SIZES.items():
        resized = resize_image(image_file=image_file, max_size=dimensions)
        path = f"thumbnails/{base_name}_{size_name}.jpg"
        from django.core.files.storage import default_storage
        saved_path = default_storage.save(path, ContentFile(resized.read()))
        paths[size_name] = saved_path
        image_file.seek(0)  # Reset for next size
    return paths
```

### Image Validation
```python
from PIL import Image, UnidentifiedImageError

MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB
ALLOWED_FORMATS = {"JPEG", "PNG", "WEBP", "GIF"}

class ImageValidationError(Exception):
    pass

def validate_image(file: InMemoryUploadedFile) -> Image.Image:
    """Validate uploaded image file."""
    if file.size and file.size > MAX_IMAGE_SIZE:
        raise ImageValidationError(f"Image too large: {file.size} bytes")
    try:
        img = Image.open(file)
        img.verify()  # Verify it's actually an image
        file.seek(0)
        img = Image.open(file)  # Re-open after verify
    except (UnidentifiedImageError, Exception) as e:
        raise ImageValidationError(f"Invalid image file: {e}")
    if img.format and img.format not in ALLOWED_FORMATS:
        raise ImageValidationError(f"Unsupported format: {img.format}")
    return img
```

### WebP Conversion
```python
def convert_to_webp(*, image_file, quality: int = 80) -> io.BytesIO:
    """Convert image to WebP format for web performance."""
    img = Image.open(image_file)
    if img.mode == "RGBA":
        buffer = io.BytesIO()
        img.save(buffer, format="WEBP", quality=quality, lossless=False)
    else:
        img = img.convert("RGB")
        buffer = io.BytesIO()
        img.save(buffer, format="WEBP", quality=quality)
    buffer.seek(0)
    return buffer
```

## Anti-Patterns
- Processing images in views — move to services
- No image validation before processing — decompression bombs
- Saving processed images to temp directories — use proper storage
- Processing images synchronously for large batches — use Celery

## Red Flags
- `Image.open()` without `verify()` — unvalidated input
- No file size limit on image uploads
- Missing `seek(0)` after reading file — empty reads on second pass

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
