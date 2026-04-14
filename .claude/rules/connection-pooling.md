---
paths: ["app/settings*.py"]
---

# Connection Pooling

Rules for database and Redis connection management across environments.

## Database Connections

- `CONN_MAX_AGE = 0` in development — close connections after each request for clean state.
- `CONN_MAX_AGE = 600` in production — reuse connections for up to 10 minutes.
- `CONN_HEALTH_CHECKS = True` (Django 4.1+) — validate connections before reuse, drop stale ones.
- NEVER set `CONN_MAX_AGE = None` (unlimited) — leaked connections exhaust the pool.
- In production, use `django-db-connection-pool` or external `pgbouncer` for proper pooling.

## Pool Sizing

- Web workers: pool size = expected concurrent requests per process (typically 5–20).
- Celery workers: use a separate, smaller pool — Celery tasks are often I/O-bound with fewer concurrent DB needs.
- NEVER share a single connection pool between web and Celery processes — configure independently.
- PostgreSQL `max_connections` MUST exceed total pool size across all workers + monitoring tools.
- Monitor with `SELECT count(*) FROM pg_stat_activity` — alert if approaching `max_connections`.

## Redis Connections

- Use Django's `CACHES` configuration for Redis cache connections — never raw `redis.Redis()`.
- Celery broker and result backend connections are managed by Celery — configure via `CELERY_BROKER_URL`.
- Set `CONNECTION_POOL_KWARGS = {"max_connections": N}` to cap Redis connections per process.
- Use `SOCKET_TIMEOUT` and `SOCKET_CONNECT_TIMEOUT` to fail fast on Redis unavailability.

## Troubleshooting

- "too many connections" → increase PostgreSQL `max_connections` or reduce `CONN_MAX_AGE`.
- Stale connections after deploy → set `CONN_HEALTH_CHECKS = True` or restart workers.
- Connection leaks in tests → ensure `CONN_MAX_AGE = 0` in test settings.
- Celery "connection reset" errors → check Redis `maxclients` and timeout settings.
