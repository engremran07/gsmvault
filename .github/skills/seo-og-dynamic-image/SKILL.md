---
name: seo-og-dynamic-image
description: "Dynamic Open Graph image generation. Use when: generating OG images for social sharing, creating branded preview images for blog posts, firmware pages."
---

# Dynamic Open Graph Image Generation

## When to Use

- Generating branded OG images for social media sharing
- Creating preview images for blog posts, firmware pages, device pages
- Building an image generation pipeline with Pillow

## Rules

### OG Image Generation Service

```python
# apps/seo/services.py
from io import BytesIO
from pathlib import Path

from django.conf import settings
from PIL import Image, ImageDraw, ImageFont

OG_WIDTH = 1200
OG_HEIGHT = 630
FONT_DIR = Path(settings.BASE_DIR) / "static" / "fonts"


def generate_og_image(
    title: str,
    subtitle: str = "",
    brand_color: str = "#0ea5e9",
) -> BytesIO:
    """Generate a 1200x630 Open Graph image with title overlay."""
    img = Image.new("RGB", (OG_WIDTH, OG_HEIGHT), color="#0f172a")
    draw = ImageDraw.Draw(img)

    # Brand accent bar
    draw.rectangle([(0, 0), (OG_WIDTH, 8)], fill=brand_color)

    # Title text
    try:
        title_font = ImageFont.truetype(str(FONT_DIR / "Inter-Bold.woff2"), 52)
    except OSError:
        title_font = ImageFont.load_default()
    # Wrap title
    _draw_wrapped_text(draw, title, title_font, OG_WIDTH - 120, x=60, y=200)

    # Subtitle
    if subtitle:
        try:
            sub_font = ImageFont.truetype(str(FONT_DIR / "Inter-Regular.woff2"), 28)
        except OSError:
            sub_font = ImageFont.load_default()
        draw.text((60, 460), subtitle, fill="#94a3b8", font=sub_font)

    # Site name watermark
    draw.text((60, 560), "GSMFWs", fill="#475569", font=title_font)

    buffer = BytesIO()
    img.save(buffer, format="PNG", optimize=True)
    buffer.seek(0)
    return buffer


def _draw_wrapped_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.FreeTypeFont,
    max_width: int,
    x: int,
    y: int,
) -> None:
    """Draw text with word wrapping."""
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        test = f"{current} {word}".strip()
        bbox = draw.textbbox((0, 0), test, font=font)
        if bbox[2] - bbox[0] <= max_width:
            current = test
        else:
            lines.append(current)
            current = word
    if current:
        lines.append(current)
    for i, line in enumerate(lines[:3]):  # max 3 lines
        draw.text((x, y + i * 64), line, fill="#f8fafc", font=font)
```

### Template Meta Tags

```html
<!-- templates/base/base.html -->
<meta property="og:image" content="{{ og_image_url }}" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<meta property="og:image:type" content="image/png" />
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:image" content="{{ og_image_url }}" />
```

### OG Image Endpoint

```python
# apps/seo/views.py
from django.http import HttpResponse

def og_image_view(request, slug: str) -> HttpResponse:
    """Serve a dynamically generated OG image."""
    # Fetch page title from Metadata model
    from apps.seo.models import Metadata
    meta = Metadata.objects.filter(path__contains=slug).first()
    title = meta.title if meta else slug.replace("-", " ").title()
    buffer = generate_og_image(title=title, subtitle="Firmware Distribution")
    return HttpResponse(buffer.getvalue(), content_type="image/png")
```

### Caching Strategy

| Approach | When |
|----------|------|
| File-system cache | Save to `media/og/` on first generation |
| Cache header | `Cache-Control: public, max-age=86400` |
| Invalidate on edit | Delete cached image when title changes |

## Anti-Patterns

- Generating images on every request — cache aggressively
- Hardcoding font paths without fallback — use `load_default()` fallback
- Images larger than 1200x630 — wastes bandwidth, platforms resize anyway
- Missing Twitter card meta — lost engagement on Twitter/X

## Red Flags

- No `try/except` on font loading — crashes if font file missing
- OG image URL not absolute — social platforms need full URL
- No word wrapping — long titles overflow the image
- Image generation in template tag — use a view endpoint

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
