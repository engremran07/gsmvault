---
paths: ["apps/*/tasks.py"]
---

# Celery Tasks

Rules for Celery task definitions across all apps. Broker and result backend are Redis.

## Task Declaration

- ALWAYS use `@shared_task(bind=True)` to enable `self.retry()` access.
- Set `max_retries=3` and `default_retry_delay=60` on every task.
- Use `autoretry_for=(ConnectionError, TimeoutError)` for known transient failures.
- Set `acks_late=True` on tasks that MUST complete — ensures re-delivery on worker crash.
- Declare `soft_time_limit` for graceful shutdown and `time_limit` for hard kill on every long-running task.

## Idempotency

- Tasks MUST be idempotent — safe to execute multiple times with the same arguments.
- Use database state checks at task start to skip already-completed work.
- NEVER rely on task execution order — assume concurrent and out-of-order delivery.
- Guard side effects (emails, webhooks, charges) with idempotency keys or status flags.

## Arguments & Serialization

- NEVER pass full model instances — pass PKs and re-query inside the task.
- NEVER access `request`, `session`, or any WSGI/ASGI objects in tasks.
- Keep arguments JSON-serializable: `int`, `str`, `float`, `bool`, `list`, `dict`, `None`.
- Avoid large payloads — store data in DB or cache, pass reference keys.

## Logging & Observability

- Log task start with task ID and arguments: `logger.info("Task %s started", self.request.id)`.
- Log task completion with duration and result summary.
- Log task failure with full context before raising or retrying.
- Use `logger.exception()` on unexpected errors to capture traceback.
- Include `task_id` in all log messages for traceability.

## Scheduling

- Beat schedule lives in `app/celery.py` — use `crontab()` for cron-style scheduling.
- Periodic tasks MUST have `expires` set to prevent stale task buildup.
- NEVER schedule tasks more frequently than their average execution time.
- Use `solar()` schedules only when time-zone-aware scheduling is required.

## Error Handling

- Retry transient errors (network, lock contention) — fail permanent errors immediately.
- Use exponential backoff: `self.retry(countdown=2 ** self.request.retries * 60)`.
- After `max_retries` exhausted, log as ERROR and emit an event via `EventBus`.
- NEVER silently swallow exceptions — always log before suppressing.
