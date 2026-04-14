# /fixture-generate â€” Generate test fixtures from the database

Export model data as JSON fixtures for testing and development seeding.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Identify Target Models

- [ ] Parse `$ARGUMENTS` for app label and optional model name (e.g., `firmwares`, `firmwares.Brand`)

- [ ] Verify the app exists in `apps/` and the model is registered

- [ ] Determine output path: `apps/<app>/fixtures/<app>_<model>.json` (or `<app>_all.json` for full app)

### Step 2: Export Fixture Data

- [ ] Run: `& .\.venv\Scripts\python.exe manage.py dumpdata <app>[.<Model>] --indent=2 --settings=app.settings_dev -o <output_path>`

- [ ] If specific records needed, use `--pks` flag to limit export

- [ ] For related data, include `--natural-foreign --natural-primary` flags

### Step 3: Validate Fixture

- [ ] Verify JSON is valid and well-formed

- [ ] Check fixture loads cleanly: `& .\.venv\Scripts\python.exe manage.py loaddata <output_path> --settings=app.settings_dev`

- [ ] Ensure no sensitive data (passwords, tokens, API keys) leaked into fixture â€” scrub if needed

- [ ] Confirm `fixtures/` directory exists in the app (create if missing)

### Step 4: Document

- [ ] Add fixture filename to app's test documentation if applicable

- [ ] Verify fixture is gitignored if it contains environment-specific data
