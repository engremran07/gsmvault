# /split-godfile â€” Identify and split oversized Python files

Find .py files exceeding 500 lines and split them into logical submodules while preserving all imports and functionality.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Identify God Files

- [ ] Scan `apps/` for all `.py` files exceeding 500 lines

- [ ] If $ARGUMENTS specifies an app or file, focus on that scope

- [ ] Sort by line count descending

- [ ] Exclude migration files (`migrations/*.py`)

### Step 2: Analyze Each God File

- [ ] Count classes, functions, and imports in the file

- [ ] Identify logical groupings (by class, by domain concern, by layer)

- [ ] Map internal cross-references (what calls what within the file)

- [ ] Map external imports (what other files import from this file)

### Step 3: Plan the Split

- [ ] Propose submodule structure (e.g., `services/` directory with `__init__.py`)

- [ ] Ensure each submodule is cohesive (single responsibility)

- [ ] Plan `__init__.py` re-exports to preserve existing import paths

- [ ] Verify no circular imports in the proposed structure

### Step 4: Execute the Split

- [ ] Create the subdirectory and `__init__.py`

- [ ] Move logical groups into separate files

- [ ] Add re-exports in `__init__.py` for backward compatibility

- [ ] Update any internal imports within the split modules

### Step 5: Verify

- [ ] Run `& .\.venv\Scripts\python.exe -m ruff check . --fix`

- [ ] Run `& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev`

- [ ] Grep for all imports of the original module â€” confirm they still resolve

- [ ] Run tests for the affected app: `& .\.venv\Scripts\python.exe -m pytest apps/<app>/ -v`

### Step 6: Rules

- [ ] NEVER create versioned files (`_v2.py`, `_new.py`) â€” edit in place or split into submodules

- [ ] Preserve `db_table` on any moved models

- [ ] Keep backward-compatible imports via `__init__.py` re-exports
