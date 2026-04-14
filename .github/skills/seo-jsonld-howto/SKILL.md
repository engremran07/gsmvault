---
name: seo-jsonld-howto
description: "JSON-LD HowTo schema. Use when: adding step-by-step guide structured data, firmware flashing tutorials, how-to rich snippets."
---

# JSON-LD HowTo Schema

## When to Use

- Adding HowTo rich snippets to tutorial/guide pages
- Firmware flashing step-by-step instructions
- Blog posts with numbered procedures

## Rules

### Schema Structure

```python
# apps/seo/services.py
def build_howto_schema(
    name: str,
    description: str,
    steps: list[dict[str, str]],
    total_time: str | None = None,
    image: str | None = None,
) -> dict:
    """Build JSON-LD HowTo schema.
    steps: list of {'name': 'Step title', 'text': 'Step details', 'image': 'optional_url'}
    total_time: ISO 8601 duration e.g. 'PT30M' for 30 minutes.
    """
    schema: dict = {
        "@context": "https://schema.org",
        "@type": "HowTo",
        "name": name,
        "description": description,
        "step": [
            {
                "@type": "HowToStep",
                "position": i + 1,
                "name": step["name"],
                "text": step["text"],
                **({"image": step["image"]} if step.get("image") else {}),
            }
            for i, step in enumerate(steps)
        ],
    }
    if total_time:
        schema["totalTime"] = total_time
    if image:
        schema["image"] = image
    return schema
```

### Firmware Flashing Example

```python
def build_firmware_flash_howto(firmware, site_url: str) -> dict:
    """Generate HowTo for firmware installation."""
    steps = [
        {"name": "Download firmware", "text": f"Download {firmware.filename} from the download page."},
        {"name": "Extract files", "text": "Extract the ZIP archive to a folder on your computer."},
        {"name": "Connect device", "text": f"Connect your {firmware.model.name} via USB cable."},
        {"name": "Launch flash tool", "text": "Open the appropriate flash tool for your device."},
        {"name": "Load firmware", "text": "Select the extracted firmware file in the flash tool."},
        {"name": "Start flashing", "text": "Click Start/Flash and wait for completion."},
    ]
    return build_howto_schema(
        name=f"How to Flash {firmware.model.name} Firmware",
        description=f"Step-by-step guide to install {firmware.filename} on {firmware.model.name}.",
        steps=steps,
        total_time="PT15M",
    )
```

### Google Requirements

| Field | Required | Notes |
|-------|----------|-------|
| `name` | Yes | Title of the how-to |
| `step` | Yes | At least 2 steps |
| `step.name` | Yes | Step title |
| `step.text` | Yes | Step description |
| `totalTime` | Recommended | ISO 8601 duration |
| `image` | Recommended | Main image |

## Anti-Patterns

- Single-step HowTo — must have at least 2 steps
- Steps without `position` — always include sequential position
- `totalTime` in wrong format — must be ISO 8601 (e.g., `PT30M`, `PT1H30M`)

## Red Flags

- Steps array is empty
- Step text contains unsanitized HTML
- Missing `@context` or `@type`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
