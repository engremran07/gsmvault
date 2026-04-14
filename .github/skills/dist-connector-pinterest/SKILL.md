---
name: dist-connector-pinterest
description: "Pinterest distribution connector. Use when: creating pins, board management, rich pins, image-focused distribution."
---

# Pinterest Distribution Connector

## When to Use
- Creating pins from blog posts or firmware pages
- Configuring `SocialAccount(channel="pinterest")` with API v5
- Auto-pinning images from content to specific boards
- Scheduling pin creation via `ShareJob`

## Rules
- Channel constant: `Channel.PINTEREST = "pinterest"`
- Pinterest API v5 with OAuth 2.0
- Pins require an image URL — no text-only pins
- Board ID stored in `SocialAccount.config["board_id"]`
- Rate limit: 1000 calls per day per user token
- Rich Pins: requires meta tags on destination page (Open Graph)

## Patterns

### Creating a Pin
```python
# apps/distribution/connectors/pinterest.py
import httpx

PINTEREST_API = "https://api.pinterest.com/v5"

def create_pin(*, job) -> dict:
    account = job.account
    payload = job.payload or {}
    board_id = account.config.get("board_id", "")

    body = {
        "board_id": board_id,
        "title": payload.get("title", "")[:100],
        "description": payload.get("text", "")[:500],
        "link": payload.get("link", ""),
        "media_source": {
            "source_type": "image_url",
            "url": payload.get("image_url", ""),
        },
    }

    resp = httpx.post(
        f"{PINTEREST_API}/pins",
        headers={"Authorization": f"Bearer {account.access_token}"},
        json=body,
        timeout=30,
    )
    resp.raise_for_status()
    result = resp.json()
    job.external_post_id = result.get("id", "")
    job.status = "completed"
    job.save(update_fields=["external_post_id", "status"])
    return result
```

### Auto-Pin from Blog Post
```python
def auto_pin_from_post(*, post, account: SocialAccount) -> ShareJob:
    """Create a ShareJob to pin the blog post's featured image."""
    from apps.distribution.models import ShareJob
    return ShareJob.objects.create(
        post=post,
        account=account,
        channel="pinterest",
        payload={
            "title": post.title[:100],
            "text": post.meta_description[:500],
            "link": post.get_absolute_url(),
            "image_url": post.featured_image.url if post.featured_image else "",
        },
    )
```

## Anti-Patterns
- Creating pins without images — API rejects
- Exceeding 1000 API calls/day — token suspended
- Not setting `link` on pins — misses referral traffic
- Duplicate pins to same board — Pinterest penalizes

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
