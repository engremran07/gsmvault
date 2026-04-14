---
name: dist-connector-linkedin
description: "LinkedIn distribution connector. Use when: posting to LinkedIn profiles/pages, Share API, article publishing, professional content distribution."
---

# LinkedIn Distribution Connector

## When to Use
- Publishing content to LinkedIn via Share API
- Configuring `SocialAccount(channel="linkedin")` with OAuth 2.0
- Publishing long-form articles or short posts
- Scheduling LinkedIn posts via `ShareJob`

## Rules
- Channel constant: `Channel.LINKEDIN = "linkedin"`
- Uses LinkedIn Marketing API with OAuth 2.0
- Post limit: 1300 characters for text, articles have no limit
- Rate limit: 100 API calls per day per member
- Images require pre-registration upload then asset URN
- Access tokens expire in 60 days — refresh required

## Patterns

### Posting a LinkedIn Share
```python
# apps/distribution/connectors/linkedin.py
import httpx

LINKEDIN_API = "https://api.linkedin.com/v2"

def post_share(*, job) -> dict:
    account = job.account
    payload = job.payload or {}
    author_urn = account.config.get("person_urn", "")

    body = {
        "author": author_urn,
        "lifecycleState": "PUBLISHED",
        "specificContent": {
            "com.linkedin.ugc.ShareContent": {
                "shareCommentary": {"text": payload.get("text", "")[:1300]},
                "shareMediaCategory": "ARTICLE" if payload.get("link") else "NONE",
            }
        },
        "visibility": {"com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"},
    }

    if link := payload.get("link"):
        body["specificContent"]["com.linkedin.ugc.ShareContent"]["media"] = [{
            "status": "READY",
            "originalUrl": link,
        }]

    resp = httpx.post(
        f"{LINKEDIN_API}/ugcPosts",
        headers={
            "Authorization": f"Bearer {account.access_token}",
            "X-Restli-Protocol-Version": "2.0.0",
        },
        json=body,
        timeout=30,
    )
    resp.raise_for_status()
    job.external_post_id = resp.headers.get("x-restli-id", "")
    job.status = "completed"
    job.save(update_fields=["external_post_id", "status"])
    return resp.json()
```

## Anti-Patterns
- Exceeding 100 API calls/day — LinkedIn suspends app access
- Not including `X-Restli-Protocol-Version` header — API rejects requests
- Posting >1300 chars — truncated silently
- Storing person URN in code instead of `SocialAccount.config`

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
