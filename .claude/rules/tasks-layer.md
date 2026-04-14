---
paths: ["apps/*/tasks.py"]
---

# Celery Tasks Layer Rules

All asynchronous processing uses Celery with Redis as the broker. Tasks live in `tasks.py` per app.

## Task Declaration

- ALWAYS use `@shared_task(bind=True)` for retry support and task instance access.
- Set `max_retries`, `default_retry_delay`, and `autoretry_for` on every task:
  ```python
  @shared_task(bind=True, max_retries=3, default_retry_delay=60, autoretry_for=(ConnectionError,))
  def process_firmware(self, firmware_id: int) -> None:
  ```
- ALWAYS type-hint task parameters and return types.
- Task names auto-derive from the module path — NEVER set `name` manually unless required.

## Idempotency

- Tasks MUST be idempotent — safe to re-run without side effects.
- Use database checks before creating records: `get_or_create()`, `update_or_create()`.
- Guard against duplicate execution with unique constraints or status checks.
- NEVER assume a task will run exactly once — network errors and restarts cause retries.

## Task Parameters

- Pass only primitive types as task arguments: `int`, `str`, `float`, `bool`, `list`, `dict`.
- NEVER pass Django model instances — pass `pk` and re-query inside the task.
- NEVER pass `request` or `session` objects — tasks run outside the request cycle.
- Keep argument payloads small — for large data, write to storage and pass a reference.

## Error Handling & Logging

- Log task start, completion, and failure with structured logging:
  ```python
  logger.info("Task %s started", self.request.id, extra={"firmware_id": firmware_id})
  ```
- Use `self.retry(exc=exc)` for transient failures — not bare `raise`.
- Set `acks_late=True` on tasks that must not be lost on worker crash.
- NEVER catch and swallow exceptions silently — always log before retry or re-raise.

## Performance

- Set `time_limit` and `soft_time_limit` on long-running tasks to prevent worker starvation.
- Use `task.apply_async(countdown=N)` for delayed execution — not `time.sleep()`.
- Batch operations with chunked processing for large datasets.
- NEVER hold database connections open during long I/O operations — use short transactions.

## Testing

- Test tasks synchronously with `CELERY_ALWAYS_EAGER=True` in test settings.
- Assert task return values and side effects (DB state, file creation).
- Test retry behavior by mocking the failing dependency.
