---
name: dist-batch-distribution
description: "Batch distribution: multi-platform fanout. Use when: distributing to multiple channels simultaneously, SharePlan execution, batch job processing."
---

# Batch Distribution

## When to Use
- Executing a `SharePlan` with multiple `ShareJob` records across channels
- Coordinating multi-platform fanout via Celery tasks
- Processing job queues with rate limiting per platform
- Using `correlation_id` to track related jobs

## Rules
- `SharePlan` groups multiple `ShareJob` records for one piece of content
- Each `ShareJob` has independent status and retry tracking
- `ShareJob.correlation_id` links all jobs from the same batch
- Process jobs sequentially per channel (rate limits) but parallel across channels
- `DistributionSettings.distribution_frequency_hours` = minimum gap between distributions
- Failed jobs don't block other channels — independent execution

## Patterns

### Batch Execution Task
```python
# apps/distribution/tasks.py
from celery import shared_task
from apps.distribution.models import SharePlan, ShareJob

@shared_task(name="distribution.execute_plan")
def execute_plan(plan_id: int) -> dict:
    """Execute all pending jobs in a distribution plan."""
    plan = SharePlan.objects.get(pk=plan_id)
    if plan.status != "approved":
        return {"status": "skipped", "reason": "Plan not approved"}

    jobs = ShareJob.objects.filter(plan=plan, status="pending")
    results = {"total": jobs.count(), "succeeded": 0, "failed": 0}

    for job in jobs:
        try:
            execute_single_job.delay(job.pk)
            results["succeeded"] += 1
        except Exception:
            results["failed"] += 1

    plan.status = "completed" if results["failed"] == 0 else "partial"
    plan.save(update_fields=["status"])
    return results

@shared_task(
    name="distribution.execute_job",
    bind=True,
    max_retries=3,
    default_retry_delay=1800,
)
def execute_single_job(self, job_id: int) -> dict:
    job = ShareJob.objects.select_related("account").get(pk=job_id)
    try:
        result = dispatch_to_connector(job=job)
        job.status = "completed"
        job.save(update_fields=["status"])
        return result
    except Exception as exc:
        job.attempt_count += 1
        job.last_error = str(exc)[:500]
        job.status = "failed" if job.attempt_count >= 3 else "retrying"
        job.save(update_fields=["attempt_count", "last_error", "status"])
        raise self.retry(exc=exc)
```

### Correlation Tracking
```python
import uuid

def create_batch(*, post, channels: list[str]) -> list[ShareJob]:
    correlation_id = str(uuid.uuid4())
    jobs = []
    for channel in channels:
        account = SocialAccount.objects.filter(
            channel=channel, is_active=True,
        ).first()
        if account:
            jobs.append(ShareJob(
                post=post, account=account, channel=channel,
                correlation_id=correlation_id,
            ))
    return ShareJob.objects.bulk_create(jobs)
```

## Anti-Patterns
- Sequential execution of all channels in one task — one failure blocks all
- No correlation ID — can't track which jobs belong to same batch
- Ignoring `attempt_count` — retrying indefinitely
- Not checking `distribution_frequency_hours` gap between batches

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
