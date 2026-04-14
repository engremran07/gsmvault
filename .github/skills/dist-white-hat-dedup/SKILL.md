---
name: dist-white-hat-dedup
description: "Content deduplication for distribution. Use when: preventing duplicate posts to same channel, detecting cross-post duplicates, idempotent job execution."
---

# Content Deduplication

## When to Use
- Preventing the same content from being posted twice to a channel
- Detecting duplicate `ShareJob` records for the same post + channel
- Ensuring idempotent job execution (safe to retry without duplicating)
- Cleaning up duplicate distribution entries

## Rules
- Unique constraint: one `ShareJob` per (post, channel, account) tuple
- Check `external_post_id` — if set, post already exists on platform
- Before creating new jobs, check for existing completed jobs
- `ShareJob.status = "completed"` + matching post/channel → skip
- Content hash for detecting near-duplicate text across channels
- Dedup check happens in `create_auto_plan()` before job creation

## Patterns

### Dedup Before Job Creation
```python
# apps/distribution/services.py
from apps.distribution.models import ShareJob

def create_job_if_not_exists(
    *, post, account, channel: str, plan=None, payload: dict | None = None,
) -> ShareJob | None:
    """Create a ShareJob only if no completed/pending job exists."""
    existing = ShareJob.objects.filter(
        post=post,
        account=account,
        channel=channel,
        status__in=["pending", "completed", "retrying"],
    ).exists()

    if existing:
        return None  # Already distributed or in progress

    return ShareJob.objects.create(
        post=post,
        account=account,
        channel=channel,
        plan=plan,
        payload=payload or {},
    )
```

### Idempotent Execution Guard
```python
def execute_job_idempotent(*, job: ShareJob) -> dict:
    """Execute job with idempotency — safe to call multiple times."""
    if job.status == "completed" and job.external_post_id:
        return {"status": "already_completed", "id": job.external_post_id}

    # Mark as in-progress to prevent concurrent execution
    updated = ShareJob.objects.filter(
        pk=job.pk, status="pending",
    ).update(status="in_progress")

    if updated == 0:
        # Another worker already picked this up
        return {"status": "already_processing"}

    job.refresh_from_db()
    return dispatch_to_connector(job=job)
```

### Content Hash for Near-Duplicate Detection
```python
import hashlib

def content_hash(text: str) -> str:
    """Generate hash of content for dedup comparison."""
    normalized = " ".join(text.lower().split())
    return hashlib.sha256(normalized.encode()).hexdigest()[:16]

def is_near_duplicate(*, post, channel: str) -> bool:
    """Check if similar content was recently posted to this channel."""
    recent_jobs = ShareJob.objects.filter(
        channel=channel, status="completed",
        created_at__gte=timezone.now() - timedelta(hours=24),
    )
    new_hash = content_hash(post.title + post.meta_description)
    for job in recent_jobs:
        old_hash = content_hash(job.payload.get("text", ""))
        if old_hash == new_hash:
            return True
    return False
```

## Anti-Patterns
- No dedup — same blog post shared to Twitter 5 times on retries
- Relying on DB unique constraint alone — doesn't catch near-duplicates
- No `external_post_id` check — can't verify if post exists on platform
- Deleting failed jobs before retry — loses error context

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
