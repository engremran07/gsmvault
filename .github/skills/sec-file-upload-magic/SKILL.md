---
name: sec-file-upload-magic
description: "Magic byte validation for file uploads. Use when: verifying file content matches format, detecting disguised executables."
---

# Magic Byte Validation

## When to Use

- Verifying file content matches expected format
- Detecting renamed executables (.exe → .jpg)
- Deep file validation beyond MIME type

## Rules

| Format | Magic Bytes (hex) | Offset |
|--------|-------------------|--------|
| ZIP | `50 4B 03 04` | 0 |
| RAR | `52 61 72 21` | 0 |
| 7z | `37 7A BC AF` | 0 |
| PNG | `89 50 4E 47` | 0 |
| JPEG | `FF D8 FF` | 0 |
| PDF | `25 50 44 46` | 0 |
| EXE/PE | `4D 5A` | 0 (REJECT) |
| ELF | `7F 45 4C 46` | 0 (REJECT) |

## Patterns

### Magic Byte Checker
```python
MAGIC_SIGNATURES = {
    "zip": b"\x50\x4b\x03\x04",
    "rar": b"\x52\x61\x72\x21",
    "7z": b"\x37\x7a\xbc\xaf",
    "png": b"\x89\x50\x4e\x47",
    "jpeg": b"\xff\xd8\xff",
    "pdf": b"\x25\x50\x44\x46",
}

DANGEROUS_SIGNATURES = {
    "exe": b"\x4d\x5a",       # PE executable
    "elf": b"\x7f\x45\x4c\x46",  # Linux executable
    "mach-o": b"\xcf\xfa\xed\xfe",  # macOS executable
}

def validate_magic_bytes(uploaded_file, allowed_types: set[str]) -> str:
    """Validate file magic bytes. Returns detected type."""
    header = uploaded_file.read(16)
    uploaded_file.seek(0)
    # Check for dangerous file types first
    for name, sig in DANGEROUS_SIGNATURES.items():
        if header.startswith(sig):
            raise ValidationError(f"Executable files ({name}) are not allowed.")
    # Check for allowed types
    for name, sig in MAGIC_SIGNATURES.items():
        if header.startswith(sig) and name in allowed_types:
            return name
    raise ValidationError("File format not recognized or not allowed.")
```

### Usage in Service Layer
```python
def process_firmware_upload(uploaded_file, user):
    file_type = validate_magic_bytes(
        uploaded_file,
        allowed_types={"zip", "rar", "7z"},
    )
    # Continue processing...
```

### Combined Validation Pipeline
```python
def full_file_validation(uploaded_file, allowed_types: set[str]) -> None:
    """Run all file validation checks in order."""
    # 1. Size check
    if uploaded_file.size > MAX_FILE_SIZE:
        raise ValidationError("File too large.")
    # 2. Extension check
    ext = os.path.splitext(uploaded_file.name.lower())[1].lstrip(".")
    if ext not in allowed_types:
        raise ValidationError(f"Extension .{ext} not allowed.")
    # 3. Magic byte validation
    validate_magic_bytes(uploaded_file, allowed_types)
    # 4. MIME type cross-check
    mime = magic.from_buffer(uploaded_file.read(2048), mime=True)
    uploaded_file.seek(0)
```

## Red Flags

- No magic byte check — renamed `.exe` files pass extension check
- Only checking first 2 bytes (some formats need 4+ bytes)
- Not rejecting known executable signatures
- Missing `seek(0)` after reading header bytes

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
