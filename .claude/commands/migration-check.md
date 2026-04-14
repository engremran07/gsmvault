# /migration-check â€” Verify migration consistency

Check Django migrations for conflicts, missing migrations, squash candidates, and schema drift.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Missing Migrations

- [ ] Run `& .\.venv\Scripts\python.exe manage.py makemigrations --check --dry-run --settings=app.settings_dev`

- [ ] If new migrations are detected, list the affected apps and model changes

- [ ] Verify all model changes have corresponding migrations

### Step 2: Migration Conflicts

- [ ] Check for migration files with the same number in any app

- [ ] Run `& .\.venv\Scripts\python.exe manage.py showmigrations --settings=app.settings_dev`

- [ ] Look for branching migrations (multiple leaf nodes in same app)

- [ ] If conflicts exist, plan resolution (merge migration)

### Step 3: Unapplied Migrations

- [ ] Run `& .\.venv\Scripts\python.exe manage.py showmigrations --settings=app.settings_dev | Select-String "\[ \]"`

- [ ] List all unapplied migrations

- [ ] Verify they can be applied without errors: `manage.py migrate --plan`

### Step 4: Schema Drift

- [ ] Compare model definitions against migration history

- [ ] Check for manual database changes not captured in migrations

- [ ] Verify dissolved app models have correct `db_table` in Meta

- [ ] Check `db_table = "original_app_tablename"` on migrated models

### Step 5: Squash Candidates

- [ ] Count migrations per app

- [ ] If $ARGUMENTS specifies an app, focus on that app

- [ ] Flag apps with more than 20 migrations as squash candidates

- [ ] Note: only squash migrations that are fully applied in all environments

### Step 6: Migration Quality

- [ ] Check for migrations with `RunPython` that lack reverse function

- [ ] Verify data migrations are idempotent

- [ ] Check for migrations that could cause downtime (large table alterations)

- [ ] Verify `AddField` with defaults won't lock large tables

### Step 7: Report

- [ ] Print summary: App | Migration Count | Status | Issues

- [ ] List all blocking issues (conflicts, unapplied)

- [ ] List improvement opportunities (squash, missing reverse)
