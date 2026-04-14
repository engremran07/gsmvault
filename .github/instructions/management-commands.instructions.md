---
applyTo: 'apps/*/management/commands/*.py'
---

# Management Command Instructions

## Base Pattern

All management commands inherit from `BaseCommand` and follow this structure:

```python
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = "One-line description of what this command does"

    def add_arguments(self, parser):
        parser.add_argument("--dry-run", action="store_true", help="Preview changes without applying")
        parser.add_argument("--limit", type=int, default=100, help="Max records to process")

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        limit = options["limit"]

        if dry_run:
            self.stdout.write(self.style.WARNING("DRY RUN — no changes will be made"))

        # Business logic here
        count = self._process_items(limit, dry_run)

        self.stdout.write(self.style.SUCCESS(f"Successfully processed {count} items"))

    def _process_items(self, limit, dry_run):
        # Implementation
        return 0
```

## Output Conventions

- `self.stdout.write()` for normal output — never `print()`
- `self.stderr.write()` for error output
- `self.style.SUCCESS("message")` — green text for success
- `self.style.ERROR("message")` — red text for errors
- `self.style.WARNING("message")` — yellow text for warnings
- `self.style.NOTICE("message")` — cyan text for informational
- `self.style.SQL_TABLE("message")` — for tabular/structured data

## Idempotency — MANDATORY

Commands MUST be safe to run multiple times without side effects:

```python
def handle(self, *args, **options):
    # Use get_or_create, update_or_create, or existence checks
    obj, created = MyModel.objects.get_or_create(
        slug="unique-slug",
        defaults={"name": "New Item"},
    )
    if created:
        self.stdout.write(self.style.SUCCESS(f"Created: {obj}"))
    else:
        self.stdout.write(self.style.NOTICE(f"Already exists: {obj}"))
```

## Dry-Run Option — MANDATORY for Destructive Operations

Any command that creates, modifies, or deletes data MUST support `--dry-run`:

```python
def add_arguments(self, parser):
    parser.add_argument("--dry-run", action="store_true", help="Preview changes without applying")

def handle(self, *args, **options):
    dry_run = options["dry_run"]
    items = MyModel.objects.filter(is_stale=True)

    if dry_run:
        self.stdout.write(self.style.WARNING(f"Would delete {items.count()} stale items"))
        for item in items[:10]:
            self.stdout.write(f"  - {item}")
        return

    deleted_count, _ = items.delete()
    self.stdout.write(self.style.SUCCESS(f"Deleted {deleted_count} stale items"))
```

## Error Handling

- Raise `CommandError("message")` for expected failures — Django handles exit code
- Let unexpected exceptions propagate (Django logs them with traceback)
- Use `--verbosity` option (built-in) to control output level

```python
def handle(self, *args, **options):
    verbosity = options["verbosity"]

    try:
        result = external_api_call()
    except ConnectionError as e:
        raise CommandError(f"API connection failed: {e}")

    if verbosity >= 2:
        self.stdout.write(f"API response: {result}")
```

## Argument Patterns

```python
def add_arguments(self, parser):
    # Positional argument
    parser.add_argument("app_label", type=str, help="App to process")

    # Optional with default
    parser.add_argument("--batch-size", type=int, default=500, help="Records per batch")

    # Boolean flag
    parser.add_argument("--force", action="store_true", help="Skip confirmation prompts")

    # Multiple values
    parser.add_argument("--exclude", nargs="*", default=[], help="Apps to skip")

    # Choices
    parser.add_argument("--format", choices=["json", "csv", "table"], default="table")
```

## Settings

Always run with explicit settings:

```powershell
& .\.venv\Scripts\python.exe manage.py my_command --settings=app.settings_dev
```

## File Location

Commands go in `apps/<app_name>/management/commands/<command_name>.py`. The directory structure:

```
apps/<app_name>/
  management/
    __init__.py
    commands/
      __init__.py
      my_command.py
```

Both `__init__.py` files are required (can be empty).

## Transaction Safety

For commands that modify multiple records, use atomic transactions:

```python
from django.db import transaction

def handle(self, *args, **options):
    with transaction.atomic():
        # All-or-nothing batch operation
        for item in items:
            item.status = "processed"
            item.save(update_fields=["status"])
```

## Progress Feedback

For long-running commands, report progress:

```python
def handle(self, *args, **options):
    total = MyModel.objects.count()
    for i, obj in enumerate(MyModel.objects.iterator(), 1):
        self._process(obj)
        if i % 100 == 0:
            self.stdout.write(f"  Processed {i}/{total}...")
    self.stdout.write(self.style.SUCCESS(f"Done: {total} items processed"))
```
