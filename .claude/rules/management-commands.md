---
paths: ["apps/*/management/commands/*.py"]
---

# Management Commands Rules

Management commands are CLI tools for admin operations, data seeding, maintenance, and batch processing.

## Structure

- Commands live in `apps/<appname>/management/commands/<command_name>.py`.
- ALWAYS inherit from `BaseCommand`.
- Set `help` attribute with a clear description of what the command does.
- Define arguments in `add_arguments(self, parser)` using `argparse` conventions.

## Output

- ALWAYS use `self.stdout.write()` for normal output — NEVER use `print()`.
- Use styled output for clarity:
  ```python
  self.stdout.write(self.style.SUCCESS("✓ 42 records created"))
  self.stdout.write(self.style.WARNING("⚠ 3 records skipped"))
  self.stdout.write(self.style.ERROR("✗ Failed to process batch"))
  ```
- Use `self.stderr.write()` for error output that should go to stderr.
- Include progress indicators for long-running operations (count, percentage, or progress bar).

## Safety

- Commands MUST be idempotent — safe to run multiple times without creating duplicates or corrupting data.
- ALWAYS add a `--dry-run` flag for commands that modify or delete data:
  ```python
  parser.add_argument("--dry-run", action="store_true", help="Preview changes without applying")
  ```
- In dry-run mode: report what WOULD happen, but NEVER write to the database.
- Handle `KeyboardInterrupt` gracefully — clean up partial state and report what was completed.
- Use `@transaction.atomic` for commands that modify multiple records — all-or-nothing.

## Naming Conventions

- Seed commands: `seed_<appname>` (e.g., `seed_forum`, `seed_firmwares`).
- Cleanup commands: `cleanup_<resource>` (e.g., `cleanup_expired_tokens`).
- Sync commands: `sync_<source>` (e.g., `sync_gsmarena`).
- Use underscores, not hyphens, in command filenames.

## Error Handling

- Log errors with structured context: `logger.error("Failed to process %s", item_id, exc_info=True)`.
- Return non-zero exit code on failure: `raise CommandError("Descriptive error message")`.
- NEVER swallow exceptions silently — at minimum log them as warnings.
- For batch operations: log individual failures, continue processing, report summary at end.

## Testing

- Test commands with `call_command("command_name", "--dry-run")`.
- Assert stdout/stderr output with `StringIO` capture.
- Test both success path and error handling paths.
- Test idempotency by running the command twice and asserting same final state.
