---
paths: ["apps/*/services*.py", "apps/*/views.py"]
---

# Upload Validation

All file uploads MUST be validated in the service layer before storage. Unvalidated uploads are a critical attack vector for RCE, XSS, and storage abuse.

## Validation Order

1. Check file size against maximum (enforce in both view AND service layer).
2. Validate MIME type using `python-magic` (reads file header) — NEVER trust the `Content-Type` header or extension alone.
3. Whitelist allowed extensions — NEVER use a blacklist approach.
4. Sanitize the filename: strip path components, special characters, null bytes.
5. Generate a unique filename (UUID-based) — NEVER use the user-supplied filename for storage.
6. Store the file in `MEDIA_ROOT` (outside web root).

## MIME Type Validation

- Use `python-magic` to detect the actual file type from content bytes.
- Compare detected MIME against an explicit allowlist per upload context:
  - Firmware files: specific binary formats + ZIP archives
  - Images: `image/jpeg`, `image/png`, `image/webp`, `image/gif`
  - Documents: `application/pdf`
- NEVER allow `text/html`, `application/javascript`, `application/x-httpd-php`, or executable types.
- Reject files where the detected MIME does not match the declared extension.

## Filename Handling

- Strip all path separators (`/`, `\`, `..`) — prevent path traversal.
- Remove null bytes and control characters.
- Generate storage filenames as `{uuid4}.{validated_extension}`.
- Preserve the original filename in a database field for display, but NEVER use it for storage paths.
- Limit filename length to prevent filesystem issues (max 255 characters).

## Size Limits

- Enforce `FILE_UPLOAD_MAX_MEMORY_SIZE` and `DATA_UPLOAD_MAX_MEMORY_SIZE` in Django settings.
- Service layer MUST re-check size — view-level checks can be bypassed by direct API calls.
- Firmware files: larger limits allowed but MUST be capped per tier.
- Profile images: strict small limit (e.g., 5 MB max).

## Firmware-Specific Validation

- Compute SHA-256 hash of uploaded firmware files for integrity verification.
- Compare hash against known-good hashes if available (OEM verification).
- Store hash in the database alongside the firmware record.
- Reject duplicate uploads (same hash) unless explicitly overriding.

## Storage Security

- `MEDIA_ROOT` MUST be outside the web-servable directory.
- Serve uploaded files through Django views with authentication checks — NEVER expose raw `MEDIA_URL` paths publicly for protected content.
- Use signed URLs or token-gated downloads for firmware files (see `DownloadToken`).
