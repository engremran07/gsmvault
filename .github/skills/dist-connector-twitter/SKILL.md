---
name: dist-connector-twitter
description: "Twitter/X distribution connector. Use when: posting to Twitter/X, configuring OAuth, thread creation, tweet scheduling, character limits."
---

# Twitter/X Distribution Connector

## When to Use
- Publishing content to Twitter/X via API
- Configuring `SocialAccount(channel="twitter")` credentials
- Creating tweet threads from long-form content
- Scheduling tweets via `ShareJob(channel="twitter")`

## Rules
- Channel constant: `Channel.TWITTER = "twitter"` in `apps.distribution.models`
- API v2 required — OAuth 2.0 with PKCE
- Tweet limit: 280 characters (threads for longer content)
- Media: up to 4 images or 1 video per tweet
- Rate limit: 300 tweets per 3-hour window
- Store `access_token` and `refresh_token` in `SocialAccount` (encrypted)

## Patterns

### Posting a Tweet
```python
# apps/distribution/connectors/twitter.py
import httpx
from apps.distribution.models import SocialAccount, ShareJob

TWITTER_API = "https://api.twitter.com/2/tweets"

def post_tweet(*, job: ShareJob) -> dict:
    """Post a single tweet. Returns API response."""
    account = job.account
    if account.is_expired:
        refresh_token(account)

    payload = job.payload or {}
    text = payload.get("text", "")[:280]

    response = httpx.post(
        TWITTER_API,
        headers={"Authorization": f"Bearer {account.access_token}"},
        json={"text": text},
        timeout=30,
    )
    response.raise_for_status()
    result = response.json()
    job.external_post_id = result["data"]["id"]
    job.status = "completed"
    job.save(update_fields=["external_post_id", "status"])
    return result
```

### Thread Creation from Long Content
```python
def create_thread(*, account: SocialAccount, segments: list[str]) -> list[str]:
    """Post a tweet thread. Returns list of tweet IDs."""
    tweet_ids = []
    reply_to = None

    for segment in segments:
        body = {"text": segment[:280]}
        if reply_to:
            body["reply"] = {"in_reply_to_tweet_id": reply_to}

        resp = httpx.post(
            TWITTER_API,
            headers={"Authorization": f"Bearer {account.access_token}"},
            json=body,
            timeout=30,
        )
        resp.raise_for_status()
        tweet_id = resp.json()["data"]["id"]
        tweet_ids.append(tweet_id)
        reply_to = tweet_id

    return tweet_ids
```

## Anti-Patterns
- Using API v1.1 — deprecated by Twitter
- Storing tokens in plaintext in `config` JSON — use encrypted fields
- Posting >300 tweets per 3 hours — triggers rate limit suspension
- Not checking `SocialAccount.is_expired` before API calls

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
