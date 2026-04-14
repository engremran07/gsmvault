---
name: input-file-upload-checker
description: >-
  Checks file upload validation. Use when: MIME type validation, file extension check, upload size limits, file upload security.
---

# File Upload Checker

Verifies that all file upload endpoints validate MIME type, file extension, and file size before accepting and storing files.

## Scope

- `apps/*/views.py` (file upload views)
- `apps/*/api.py` (file upload API endpoints)
- `apps/*/services.py` (file processing services)
- `apps/*/forms.py` (file upload form fields)
- `apps/storage/` (storage abstraction)

## Rules

1. All file uploads MUST validate MIME type using `python-magic` or equivalent — never trust browser-provided Content-Type
2. File extensions must be checked against an allowlist, not a blocklist
3. Maximum file size must be enforced BEFORE reading the entire file into memory
4. Uploaded files must be renamed with unique identifiers — never use user-supplied filenames directly
5. Path traversal prevention: sanitize filenames to remove `../`, `..\\`, and null bytes
6. Firmware files must have additional validation: checksum verification, format validation
7. Image uploads must be re-encoded to strip EXIF data and potential embedded scripts
8. Never serve uploaded files directly from user-accessible paths — use signed URLs or Django's FileResponse
9. Upload storage must be outside the web root — never store in `static/` or `media/` served directly
10. Temporary upload files must be cleaned up on failure — no orphaned files

## Procedure

1. Find all views/APIs that handle file uploads
2. Check each for MIME type validation
3. Verify extension allowlist enforcement
4. Check file size limits in settings and views
5. Verify filename sanitization
6. Check storage path configuration

## Output

File upload security report with endpoint, validation checks present/missing, and risk level.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
