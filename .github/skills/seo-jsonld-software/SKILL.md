---
name: seo-jsonld-software
description: "JSON-LD SoftwareApplication schema. Use when: adding firmware/software structured data, app listings, download pages with rich snippets."
---

# JSON-LD SoftwareApplication Schema

## When to Use

- Adding structured data to firmware download pages
- Flash tool software listings
- Any downloadable software with version info

## Rules

### Schema Structure

```python
# apps/seo/services.py
def build_software_schema(
    name: str,
    version: str,
    os: str,
    size: str,
    download_url: str,
    description: str = "",
    category: str = "UtilitiesApplication",
    rating: float | None = None,
    rating_count: int | None = None,
) -> dict:
    """Build JSON-LD SoftwareApplication schema."""
    schema: dict = {
        "@context": "https://schema.org",
        "@type": "SoftwareApplication",
        "name": name,
        "softwareVersion": version,
        "operatingSystem": os,
        "fileSize": size,
        "downloadUrl": download_url,
        "applicationCategory": category,
        "offers": {
            "@type": "Offer",
            "price": "0",
            "priceCurrency": "USD",
        },
    }
    if description:
        schema["description"] = description[:200]
    if rating is not None and rating_count:
        schema["aggregateRating"] = {
            "@type": "AggregateRating",
            "ratingValue": str(round(rating, 1)),
            "ratingCount": str(rating_count),
            "bestRating": "5",
            "worstRating": "1",
        }
    return schema
```

### Firmware-Specific Builder

```python
def build_firmware_software_schema(firmware, site_url: str) -> dict:
    """Build SoftwareApplication for a firmware file."""
    return build_software_schema(
        name=f"{firmware.model.brand.name} {firmware.model.name} Firmware",
        version=firmware.version or "1.0",
        os="Android" if firmware.os_type == "android" else firmware.os_type,
        size=firmware.human_file_size,
        download_url=f"{site_url}/firmwares/{firmware.pk}/download/",
        description=f"Official firmware for {firmware.model.name}",
        category="UtilitiesApplication",
    )
```

### Application Categories

| Category | Use For |
|----------|---------|
| `UtilitiesApplication` | Flash tools, firmware |
| `DeveloperApplication` | Dev tools, SDKs |
| `SecurityApplication` | Security patches |
| `DriverApplication` | Device drivers |

### Template Use

```html
{% if software_schema %}
<script type="application/ld+json">{{ software_schema|safe }}</script>
{% endif %}
```

## Anti-Patterns

- Using `SoftwareApplication` for non-software content
- Fake ratings in `aggregateRating` — must reflect real user data
- Missing `offers` block — Google requires it even for free software

## Red Flags

- `price` is not "0" for free firmware downloads
- `fileSize` missing or zero
- `downloadUrl` points to a gated page without accessible download

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
