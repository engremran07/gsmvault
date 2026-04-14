---
name: dist-connector-facebook
description: "Facebook distribution connector. Use when: posting to Facebook Pages, configuring Graph API, scheduling page posts, handling media uploads."
---

# Facebook Distribution Connector

## When to Use
- Publishing content to Facebook Pages via Graph API
- Configuring `SocialAccount(channel="facebook")` with page tokens
- Scheduling page posts via `ShareJob(channel="facebook")`
- Uploading images/videos with posts

## Rules
- Channel constant: `Channel.FACEBOOK = "facebook"`
- Uses Graph API v18+ with Page Access Token (long-lived)
- Page posts only — no personal profile posting
- Rate limit: 200 calls per user per hour
- Media uploads require separate upload endpoint then attach to post
- Store page-level `access_token` in `SocialAccount` — not user token

## Patterns

### Posting to Facebook Page
```python
# apps/distribution/connectors/facebook.py
import httpx
from apps.distribution.models import SocialAccount, ShareJob

GRAPH_API = "https://graph.facebook.com/v18.0"

def post_to_page(*, job: ShareJob) -> dict:
    account = job.account
    payload = job.payload or {}
    page_id = account.config.get("page_id", "me")

    body = {
        "message": payload.get("text", ""),
        "access_token": account.access_token,
    }
    if url := payload.get("link"):
        body["link"] = url

    response = httpx.post(
        f"{GRAPH_API}/{page_id}/feed",
        data=body,
        timeout=30,
    )
    response.raise_for_status()
    result = response.json()
    job.external_post_id = result.get("id", "")
    job.status = "completed"
    job.save(update_fields=["external_post_id", "status"])
    return result
```

### Token Refresh
```python
def refresh_long_lived_token(account: SocialAccount) -> None:
    """Exchange short-lived token for long-lived (60-day) token."""
    from django.conf import settings
    resp = httpx.get(
        f"{GRAPH_API}/oauth/access_token",
        params={
            "grant_type": "fb_exchange_token",
            "client_id": settings.FACEBOOK_APP_ID,
            "client_secret": settings.FACEBOOK_APP_SECRET,
            "fb_exchange_token": account.access_token,
        },
    )
    resp.raise_for_status()
    account.access_token = resp.json()["access_token"]
    account.token_expires_at = timezone.now() + timedelta(days=60)
    account.save(update_fields=["access_token", "token_expires_at"])
```

## Anti-Patterns
- Using user access tokens instead of page access tokens
- Not refreshing long-lived tokens before expiry (60-day cycle)
- Posting to personal profiles — Pages API only
- Exceeding 200 calls/hour — triggers temporary block

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
