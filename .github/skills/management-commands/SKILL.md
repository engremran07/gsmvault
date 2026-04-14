---
name: management-commands
description: "Custom management commands: BaseCommand, add_arguments, handle(). Use when: creating CLI tools, seed scripts, cleanup tasks, data import/export commands."
---

# Custom Management Commands

## When to Use
- Building CLI tools for admin operations
- Creating seed scripts for development data
- Building cleanup/maintenance tasks
- Data import/export operations
- One-off data fixes or migrations

## Rules
- Commands live in `apps/<app>/management/commands/<name>.py`
- ALWAYS inherit from `BaseCommand` and set `help` attribute
- Use `self.stdout.write()` — NEVER `print()`
- Style output: `self.style.SUCCESS(...)`, `self.style.WARNING(...)`, `self.style.ERROR(...)`
- ALWAYS add `--dry-run` for commands that modify data
- Commands MUST be idempotent — safe to run multiple times
- Use `@transaction.atomic` for multi-record modifications

## Patterns

### Basic Command Structure
```python
# apps/firmwares/management/commands/cleanup_expired_tokens.py
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from apps.firmwares.models import DownloadToken


class Command(BaseCommand):
    help = "Remove expired download tokens older than 7 days."

    def add_arguments(self, parser):  # type: ignore[no-untyped-def]
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Preview deletions without applying.",
        )
        parser.add_argument(
            "--days",
            type=int,
            default=7,
            help="Delete tokens older than this many days (default: 7).",
        )

    def handle(self, *args, **options):  # type: ignore[no-untyped-def]
        cutoff = timezone.now() - timezone.timedelta(days=options["days"])
        expired = DownloadToken.objects.filter(
            status="expired", expires_at__lt=cutoff
        )
        count = expired.count()

        if options["dry_run"]:
            self.stdout.write(self.style.WARNING(f"Would delete {count} expired tokens."))
            return

        with transaction.atomic():
            deleted, _ = expired.delete()

        self.stdout.write(self.style.SUCCESS(f"Deleted {deleted} expired tokens."))
```

### Seed Command
```python
# apps/forum/management/commands/seed_forum.py
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = "Seed the forum with test data for development."

    def add_arguments(self, parser):  # type: ignore[no-untyped-def]
        parser.add_argument(
            "--users", type=int, default=8, help="Number of test users",
        )
        parser.add_argument(
            "--topics", type=int, default=10, help="Number of test topics",
        )

    def handle(self, *args, **options):  # type: ignore[no-untyped-def]
        users = self._create_users(options["users"])
        self.stdout.write(self.style.SUCCESS(f"Created {len(users)} users"))

        categories = self._create_categories()
        self.stdout.write(self.style.SUCCESS(f"Created {len(categories)} categories"))

        topics = self._create_topics(users, categories, options["topics"])
        self.stdout.write(self.style.SUCCESS(f"Created {len(topics)} topics"))

    def _create_users(self, count: int) -> list:
        users = []
        for i in range(count):
            user, created = User.objects.get_or_create(
                username=f"testuser{i}",
                defaults={"email": f"test{i}@example.com"},
            )
            if created:
                user.set_password("testpass123")
                user.save()
                users.append(user)
        return users
```

### Batch Processing with Progress
```python
class Command(BaseCommand):
    help = "Recalculate trust scores for all devices."

    def handle(self, *args, **options):  # type: ignore[no-untyped-def]
        from apps.devices.models import Device
        from apps.devices.services import recalculate_trust_score

        devices = Device.objects.all()
        total = devices.count()
        success, failed = 0, 0

        for i, device in enumerate(devices.iterator(), 1):
            try:
                recalculate_trust_score(device)
                success += 1
            except Exception as e:
                self.stderr.write(self.style.ERROR(f"Failed for {device.pk}: {e}"))
                failed += 1

            if i % 100 == 0:
                self.stdout.write(f"Progress: {i}/{total}")

        self.stdout.write(
            self.style.SUCCESS(f"Done: {success} success, {failed} failed out of {total}")
        )
```

### Error Handling
```python
def handle(self, *args, **options):  # type: ignore[no-untyped-def]
    source = options["source"]
    if not Path(source).exists():
        raise CommandError(f"Source file not found: {source}")

    try:
        self._process(source)
    except KeyboardInterrupt:
        self.stderr.write(self.style.WARNING("\nAborted by user."))
        raise SystemExit(1)  # noqa: B904
```

## Anti-Patterns
- NEVER use `print()` — use `self.stdout.write()`
- NEVER skip `--dry-run` on destructive commands
- NEVER create non-idempotent commands (duplicates on re-run)
- NEVER swallow exceptions silently — log and report failures
- NEVER run commands in production without `--dry-run` first

## Red Flags
- Missing `help` attribute on Command class
- `print()` instead of `self.stdout.write()`
- No `--dry-run` on a command that deletes records
- `get_or_create` without `defaults=` causing integrity errors

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `.claude/rules/management-commands.md` — command rules
- `apps/forum/management/commands/seed_forum.py` — seed example
