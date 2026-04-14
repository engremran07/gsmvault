---
paths: ["apps/storage/**"]
---

# Storage Patterns

Rules for file storage via the `apps.storage` abstraction layer. GCS in production, local filesystem in development.

## Storage Backend Selection

- Production: Google Cloud Storage (GCS) via service account credentials.
- Development: local filesystem under `media/` — mirrors GCS path structure.
- ALWAYS use the `apps.storage` abstraction — NEVER call GCS or filesystem APIs directly.
- Storage backend is configured via Django settings — app code MUST be backend-agnostic.

## Credentials & Security

- Storage credentials live in `storage_credentials/` — this directory is gitignored.
- NEVER expose storage credentials in client-side code, templates, or API responses.
- NEVER commit service account JSON files to version control.
- Use signed URLs (time-limited) for granting temporary file access to users.
- Signed URL expiry: 15 minutes for downloads, 60 minutes for uploads.

## File Path Structure

- Organize by app, model, and date: `{app}/{model}/{YYYY}/{MM}/{DD}/{filename}`.
- Use UUIDs or hashed filenames to prevent enumeration attacks.
- NEVER use user-supplied filenames directly — sanitize or replace entirely.
- NEVER store files in web-accessible directories outside the storage abstraction.

## Upload Validation

- Validate file size BEFORE accepting upload — enforce per-tier quotas from `apps.devices.QuotaTier`.
- Whitelist allowed MIME types per upload context — NEVER accept arbitrary file types.
- Validate file extension matches MIME type — reject mismatches.
- Scan for malicious content where applicable (firmware files, user uploads).
- Set `FILE_UPLOAD_MAX_MEMORY_SIZE` and `DATA_UPLOAD_MAX_MEMORY_SIZE` in settings.

## Cleanup & Lifecycle

- Run periodic Celery task to identify and remove orphaned files (no DB reference).
- Delete storage files when the associated model instance is deleted — use `post_delete` signal.
- NEVER delete files synchronously in request/response cycle — queue for async deletion.
- Retain firmware files for the configured retention period even after soft-delete.

## Monitoring

- Track storage usage per user and per tier — expose in admin dashboard.
- Alert when storage quota approaches limits (80% threshold).
- Log all file upload and deletion events with file path, size, and user_id.
