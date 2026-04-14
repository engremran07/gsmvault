# /seed-data â€” Populate development database with test data

Run seed and management commands to fill the dev database with realistic sample data.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Determine Seed Scope

- [ ] Parse `$ARGUMENTS` for target app or `all` for full platform seeding

- [ ] Check for existing management commands: `apps/<app>/management/commands/seed_*.py`

- [ ] Verify database connectivity: `& .\.venv\Scripts\python.exe manage.py check --database default --settings=app.settings_dev`

### Step 2: Run Migrations First

- [ ] Ensure migrations are current: `& .\.venv\Scripts\python.exe manage.py migrate --settings=app.settings_dev`

- [ ] Check for pending migrations: `& .\.venv\Scripts\python.exe manage.py showmigrations --settings=app.settings_dev | Select-String "\[ \]"`

### Step 3: Execute Seed Commands

- [ ] For forum: `& .\.venv\Scripts\python.exe manage.py seed_forum --settings=app.settings_dev`

- [ ] For specific app: `& .\.venv\Scripts\python.exe manage.py seed_<app> --settings=app.settings_dev`

- [ ] For fixtures: `& .\.venv\Scripts\python.exe manage.py loaddata apps/<app>/fixtures/*.json --settings=app.settings_dev`

- [ ] For superuser: `& .\.venv\Scripts\python.exe manage.py createsuperuser --settings=app.settings_dev` (if needed)

### Step 4: Verify Seeded Data

- [ ] Spot-check record counts via Django shell or admin panel

- [ ] Confirm FK relationships are intact (no orphaned records)

- [ ] Test that seeded data renders correctly on relevant pages
