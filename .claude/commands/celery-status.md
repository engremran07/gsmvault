# /celery-status â€” Check Celery worker and task status

Inspect Celery worker health, active/reserved/scheduled tasks, and beat schedule configuration.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Check Redis Connectivity

- [ ] Verify Redis is running: `redis-cli ping` (should return PONG)

- [ ] Check Redis connection from Django: `& .\.venv\Scripts\python.exe -c "import redis; r = redis.Redis(); print(r.ping())"`

### Step 2: Inspect Celery Workers

- [ ] List active workers: `& .\.venv\Scripts\python.exe -m celery -A app inspect active`

- [ ] Check registered tasks: `& .\.venv\Scripts\python.exe -m celery -A app inspect registered`

- [ ] View reserved tasks: `& .\.venv\Scripts\python.exe -m celery -A app inspect reserved`

- [ ] View scheduled tasks: `& .\.venv\Scripts\python.exe -m celery -A app inspect scheduled`

- [ ] Worker stats: `& .\.venv\Scripts\python.exe -m celery -A app inspect stats`

### Step 3: Check Beat Schedule

- [ ] Review beat schedule in settings: periodic tasks configuration

- [ ] Verify task schedules: `aggregate_events`, `cleanup_old_events`, `scan_templates_for_ad_placements`

- [ ] Check last beat heartbeat

### Step 4: Verify Task Registration

- [ ] All app `tasks.py` files register tasks with `@shared_task` or `@app.task`

- [ ] Task names follow project convention

- [ ] No orphaned tasks (registered but no longer defined)

### Step 5: Troubleshoot (if issues found)

- [ ] Check Celery logs for errors

- [ ] Verify broker URL in settings matches running Redis instance

- [ ] Restart worker: `& .\.venv\Scripts\python.exe -m celery -A app worker -l info`

- [ ] Restart beat: `& .\.venv\Scripts\python.exe -m celery -A app beat -l info`
