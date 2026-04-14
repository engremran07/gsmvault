---
paths: ["apps/backup/**"]
---

# Backup Safety

Rules for the `apps.backup` automated backup system. Protects against data loss on PostgreSQL 17.

## Backup Schedule

- Automated daily backups of the full PostgreSQL database — no exceptions.
- Hourly WAL (Write-Ahead Log) archiving for point-in-time recovery in production.
- ALWAYS perform a backup before destructive operations: migrations, data cleanup scripts, bulk deletes.
- Backup schedule is configured via Celery Beat — NEVER rely on manual execution.

## Retention Policy

- Minimum retention: 7 days of daily backups.
- Recommended: 30 days daily + 12 months weekly + yearly archives.
- Retention policy MUST be configurable via `apps.backup` model or site settings.
- NEVER delete the most recent backup — always keep at least one valid backup available.
- Automated cleanup of expired backups via periodic Celery task.

## Storage & Security

- Store backups off-site — different storage region or provider from primary database.
- NEVER store backups in web-accessible directories.
- Encrypt backups at rest — use AES-256 or equivalent.
- Encrypt backup transfer in transit — use TLS for all backup operations.
- Backup credentials are separate from application credentials — stored in `storage_credentials/`.
- NEVER log backup file paths or credentials.

## Verification

- Periodic restore tests: automated weekly restore to a staging database.
- Verify backup integrity: checksum validation after each backup completes.
- Alert on backup failure — backup failures are CRITICAL severity events.
- Monitor backup size trends — sudden drops may indicate incomplete backups.

## Restore Procedure

- Document restore steps in an operational runbook — not just in code comments.
- Restore MUST be tested and verified before any production migration.
- Point-in-time recovery: document how to restore to a specific WAL position.
- After restore: verify data integrity with application-level consistency checks.
- After restore: invalidate all user sessions and API tokens as a security precaution.

## Media & File Backups

- Database backups do NOT include media files — backup `apps.storage` files separately.
- GCS versioning provides file-level backup for production storage.
- Local development: media files are ephemeral — do not require backup.
