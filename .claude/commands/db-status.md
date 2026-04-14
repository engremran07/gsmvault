# /db-status â€” Check database health and migration state

Verify PostgreSQL connectivity, migration status, table counts, and index usage.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Check Database Connectivity

- [ ] Run Django DB check: `& .\.venv\Scripts\python.exe manage.py check --database default --settings=app.settings_dev`

- [ ] Verify connection: `& .\.venv\Scripts\python.exe manage.py dbshell --settings=app.settings_dev` (then `\conninfo` and `\q`)

### Step 2: Check Migration State

- [ ] Show all migrations: `& .\.venv\Scripts\python.exe manage.py showmigrations --settings=app.settings_dev`

- [ ] Find unapplied migrations: `& .\.venv\Scripts\python.exe manage.py showmigrations --settings=app.settings_dev | Select-String "\[ \]"`

- [ ] Check for pending migrations: `& .\.venv\Scripts\python.exe manage.py makemigrations --check --dry-run --settings=app.settings_dev`

### Step 3: Table Statistics

- [ ] Count tables per app via Django shell:

  ```powershell
  & .\.venv\Scripts\python.exe manage.py shell --settings=app.settings_dev -c "from django.apps import apps; [print(f'{m._meta.db_table}: {m.objects.count()}') for m in apps.get_models()]"
  ```

- [ ] Identify empty tables that should have data

- [ ] Check for dissolved app tables still using `db_table` overrides

### Step 4: Index Health

- [ ] Verify indexes exist on frequently queried fields (FKs, slugs, timestamps)

- [ ] Check for missing indexes on fields used in `filter()`, `order_by()`, `get()`

- [ ] Review `class Meta: indexes = [...]` in models

### Step 5: Report

- [ ] Database version (PostgreSQL 17 expected)

- [ ] Total tables count

- [ ] Unapplied migrations count

- [ ] Apps with model changes not yet in migrations
