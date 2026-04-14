---
agent: 'agent'
description: 'Verify database migration safety including reversibility, data preservation, and dissolved model db_table retention'
tools: ['read_file', 'grep_search', 'file_search', 'run_in_terminal', 'list_dir']
---

# Migration Safety Check

Audit all Django migrations for safety, reversibility, and data preservation compliance.

## 1 — Pending Migration Detection

Run migration check to detect unapplied or unmade migrations:
```powershell
& .\.venv\Scripts\python.exe manage.py makemigrations --check --settings=app.settings_dev
```

If this produces output, there are model changes without corresponding migrations. These must be created before proceeding.

## 2 — Data-Destructive Operations

Scan all migration files in `apps/*/migrations/*.py` for potentially destructive operations:

### RemoveField
Grep for `migrations.RemoveField`. Each instance must be verified:
1. Data has been backed up or migrated to another field
2. No code references the removed field
3. A `RunPython` operation in the same or prior migration preserves data if needed

### DeleteModel
Grep for `migrations.DeleteModel`. Each instance must be verified:
1. Model data has been migrated to the target model
2. All FK references have been updated
3. Dissolved models should NOT be deleted — they should use `db_table` renaming

### AlterField (type changes)
Grep for `migrations.AlterField` where the field type changes (e.g., `CharField` → `IntegerField`). Verify:
1. Data conversion is handled
2. No data loss from type narrowing (e.g., `TextField` → `CharField(max_length=50)`)

### RemoveIndex
Index removal should be justified — the index may be needed for query performance.

## 3 — RunPython Reversibility

Every `migrations.RunPython` operation MUST have a reverse function:

```python
# CORRECT — has reverse
migrations.RunPython(forward_func, reverse_func)

# CORRECT — documented as irreversible
migrations.RunPython(forward_func, migrations.RunPython.noop)

# WRONG — no reverse at all
migrations.RunPython(forward_func)
```

Grep all migration files for `RunPython` and verify each has a reverse function or explicitly uses `RunPython.noop` with a comment explaining why reversal is impossible.

## 4 — Dissolved Model db_table Retention

Models migrated from dissolved apps MUST retain their original `db_table` to preserve existing data:

| Dissolved App | Required db_table Pattern |
|---------------|--------------------------|
| `crawler_guard` | `db_table = "crawler_guard_*"` |
| `fw_scraper` | `db_table = "fw_scraper_*"` |
| `download_links` | `db_table = "download_links_*"` |
| `admin_audit` | `db_table = "admin_audit_*"` |
| `email_system` | `db_table = "email_system_*"` |
| `webhooks` | `db_table = "webhooks_*"` |
| `ai_behavior` | `db_table = "ai_behavior_*"` |
| `device_registry` | `db_table = "device_registry_*"` |
| `gsmarena_sync` | `db_table = "gsmarena_sync_*"` |
| `fw_verification` | `db_table = "fw_verification_*"` |
| `security_suite` | `db_table = "security_suite_*"` |
| `security_events` | `db_table = "security_events_*"` |

Verify by reading the model `Meta` classes in the target apps (`apps/security/`, `apps/firmwares/`, `apps/devices/`, etc.).

## 5 — Migration Order

### Linear History
Check each app's migrations form a linear chain without forks:
```powershell
& .\.venv\Scripts\python.exe manage.py showmigrations --settings=app.settings_dev
```

All migrations should show `[X]` (applied) in order, with no gaps or branches.

### Dependency Correctness
In migration files, check `dependencies` lists reference existing migrations:
```python
dependencies = [
    ("firmwares", "0015_previous_migration"),  # Must exist
    ("devices", "0008_device_trust"),           # Cross-app dep must exist
]
```

Verify no circular dependencies between app migrations.

### Cross-App Dependencies
If migration A depends on migration B from another app, verify:
1. The dependency is necessary (model FK reference)
2. The dependency target exists
3. No circular dependency chain (A depends on B, B depends on A)

## 6 — Squashing Opportunities

Check for apps with excessive migration count:
```powershell
Get-ChildItem -Path apps\*\migrations\*.py -Exclude __init__.py | Group-Object { Split-Path (Split-Path $_.FullName -Parent) -Leaf } | Sort-Object Count -Descending | Select-Object Count, Name
```

Apps with 15+ migrations should consider squashing to improve migration performance.

## 7 — Default Values

Check `AddField` operations for proper defaults:
1. Non-nullable fields must have `default=` or be in `RunPython` to backfill
2. Boolean fields should have explicit `default=True` or `default=False`
3. Date fields using `default=django.utils.timezone.now` — verify this is intentional

## 8 — Index Safety

New indexes on large tables should use `AddIndex` with `CREATE INDEX CONCURRENTLY` on PostgreSQL:
```python
# For large tables, use concurrent index creation
class Migration(migrations.Migration):
    atomic = False  # Required for CONCURRENTLY
    operations = [
        AddIndexConcurrently(...)
    ]
```

## 9 — Foreign Key Constraints

New FK fields must specify:
1. `on_delete` behavior explicitly (`CASCADE`, `SET_NULL`, `PROTECT`, etc.)
2. `related_name` on the field itself (not just in the migration)
3. FK to dissolved app models must reference the new target app

## 10 — Test Migration Application

Verify migrations can be applied to a fresh database:
```powershell
& .\.venv\Scripts\python.exe manage.py migrate --run-syncdb --settings=app.settings_dev
```

And verify they can be reversed to a known good state:
```powershell
& .\.venv\Scripts\python.exe manage.py migrate <app_name> <previous_migration> --settings=app.settings_dev
```

## Report

```
╔══════════════════════════════════════════╗
║       MIGRATION SAFETY CHECK             ║
╠══════════════════════════════════════════╣
║  1. Pending Migrations     [✅/❌]       ║
║  2. Destructive Ops        [✅/⚠️/❌]   ║
║  3. RunPython Reversibility [✅/❌]      ║
║  4. Dissolved db_table     [✅/❌]       ║
║  5. Migration Order        [✅/❌]       ║
║  6. Squashing Review       [✅/⚠️/N/A]  ║
║  7. Default Values         [✅/❌]       ║
║  8. Index Safety           [✅/⚠️/N/A]  ║
║  9. FK Constraints         [✅/❌]       ║
║ 10. Application Test       [✅/❌]       ║
╠══════════════════════════════════════════╣
║  MIGRATION STATUS: SAFE / UNSAFE         ║
╚══════════════════════════════════════════╝
```

Any UNSAFE finding blocks deployment until resolved.
