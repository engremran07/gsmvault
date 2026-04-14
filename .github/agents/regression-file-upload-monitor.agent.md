---
name: regression-file-upload-monitor
description: >-
  Monitors file upload validation: MIME, size, extension.
  Use when: upload audit, file validation check, upload security scan.
---

# Regression File Upload Monitor

Detects file upload validation regressions: removed MIME checks, missing size limits, bypassed extension filtering.

## Rules

1. Every file upload must validate MIME type — removed validation is CRITICAL.
2. Every file upload must enforce file size limits — removed limits is HIGH.
3. Every file upload must validate file extension against an allowlist — removed check is HIGH.
4. File content must be validated (magic bytes) — not just extension — removed check is HIGH.
5. Uploaded files must not be stored with user-supplied filenames — path traversal risk is CRITICAL.
6. Firmware file uploads must go through `apps.firmwares` service layer validation.
7. Scan views, services, and forms for `request.FILES` handling without validation.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
