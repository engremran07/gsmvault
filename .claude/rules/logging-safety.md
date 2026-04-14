---
paths: ["apps/**/*.py"]
---

# Logging Safety

Rules for logging across all application code. Uses Python's `logging` module with Django configuration.

## Logger Setup

- ALWAYS use `logger = logging.getLogger(__name__)` at module level.
- NEVER use `print()` for operational logging — `print` is for management command output only.
- NEVER instantiate loggers with hardcoded names — `__name__` ensures proper hierarchy.
- Configure loggers in `app/settings.py` `LOGGING` dict — never in application code.

## Sensitive Data — NEVER Log

- NEVER log passwords, password hashes, or authentication tokens.
- NEVER log API keys, secret keys, or encryption keys.
- NEVER log session IDs, CSRF tokens, or JWT tokens.
- NEVER log PII: email addresses, phone numbers, IP addresses (unless security logger).
- NEVER log full request bodies that may contain credentials or payment data.
- NEVER log database connection strings or storage credentials.
- If you must reference a user, log `user_id` only — never username or email.

## Log Levels

- `DEBUG`: Development-only detail (query counts, cache hits, template rendering times).
- `INFO`: Operational events (task started, user registered, firmware uploaded, download completed).
- `WARNING`: Recoverable issues (cache miss, retry triggered, deprecated feature used).
- `ERROR`: Failures requiring attention (payment failed, external API error, missing required data).
- `CRITICAL`: System-level failures (database unreachable, Redis down, storage unavailable).

## Structured Context

- Include actionable context: `logger.info("Download started", extra={"user_id": uid, "firmware_id": fid})`.
- Include `request_id` for request-scoped tracing when available.
- Include `task_id` in all Celery task log messages.
- Use `logger.exception("msg")` to automatically include traceback on errors.
- NEVER use string formatting in log calls — use `logger.info("x=%s", x)` for lazy evaluation.

## Security Logging

- Security events (login failures, permission denials, rate limit hits) → dedicated security logger.
- Security logs MUST include: timestamp, event type, source IP (hashed if PII policy requires), outcome.
- NEVER log security events at DEBUG level — use INFO minimum for audit trail.
- Tamper protection: security logs should write to append-only or remote storage in production.

## Performance

- Guard expensive log construction: `if logger.isEnabledFor(logging.DEBUG):` before building debug messages.
- NEVER log inside tight loops — aggregate and log summaries instead.
- Log file rotation configured in `LOGGING` settings — never let logs grow unbounded.
