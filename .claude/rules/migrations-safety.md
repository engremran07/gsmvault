---
paths: ["apps/*/migrations/*.py"]
---

# Migrations Safety Rules

Migration files are generated artifacts. Manual edits are forbidden except for data migrations. Safety and reversibility are paramount.

## Generation Rules

- NEVER edit auto-generated migration files manually — regenerate with `manage.py makemigrations`.
- ALWAYS run `makemigrations` before `migrate` to detect pending schema changes.
- ALWAYS run `manage.py check --settings=app.settings_dev` after applying migrations.
- Commit migration files alongside the model changes that created them — never in isolation.

## Dissolved App Safety

- Dissolved app models that moved to new apps keep `db_table = "original_app_tablename"` in Meta — NEVER change this value.
- Renaming `db_table` on a dissolved model requires a manual `ALTER TABLE` data migration.
- NEVER delete migration history for dissolved apps — the database still has those tables.

## Data Migrations

- Use `migrations.RunPython(forward_func, reverse_func)` for data migrations.
- ALWAYS provide a reverse function — use `migrations.RunPython.noop` if reversal is a no-op.
- Data migrations MUST be idempotent — safe to run multiple times.
- NEVER import models directly in data migrations — use `apps.get_model("appname", "ModelName")`.
- Keep data migrations in separate files from schema migrations for clarity.

## Safe vs Risky Operations

- **Safe**: `AddField`, `AddIndex`, `AlterField` (widening), `CreateModel`, `AddConstraint`.
- **Review carefully**: `RemoveField` (data loss), `DeleteModel` (table drop), `AlterField` (narrowing), `RenameField`, `RenameModel`.
- **Dangerous**: `RunSQL` without reverse, dropping indexes on large tables, changing primary keys.
- ALWAYS back up the database before running destructive migrations in production.
- Use `--plan` flag to review migration operations before applying.

## Testing

- Test both forward and reverse migration in CI: `migrate` then `migrate <app> <previous>`.
- Verify data integrity after data migrations — add assertions in the migration function.
- NEVER assume migration order across apps — use `dependencies` to declare explicit ordering.

## Naming

- Let Django auto-name migrations (`0001_initial`, `0002_add_field_name`).
- For custom data migrations, use descriptive names: `0005_populate_default_tiers`.
- NEVER renumber or squash migrations without a full team review.
