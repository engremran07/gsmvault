---
name: dist-connector-reddit
description: "Reddit distribution connector. Use when: posting to subreddits, Reddit API, link/self posts, rate limiting, karma requirements."
---

# Reddit Distribution Connector

## When to Use
- Submitting content to relevant subreddits
- Configuring `SocialAccount(channel="reddit")` with OAuth2 credentials
- Creating link posts or self posts with formatting
- Respecting subreddit rules and Reddit rate limits

## Rules
- Channel constant: `Channel.REDDIT = "reddit"`
- Reddit API with OAuth 2.0 (script or web app flow)
- Rate limit: 60 requests per minute per OAuth token
- Subreddit stored in `SocialAccount.config["subreddit"]`
- Must include proper `User-Agent` header — Reddit blocks generic agents
- Self-promotion rules: 10:1 ratio of community content to self-promotion

## Patterns

### Submitting a Post
```python
# apps/distribution/connectors/reddit.py
import httpx

REDDIT_API = "https://oauth.reddit.com"

def submit_post(*, job) -> dict:
    account = job.account
    payload = job.payload or {}
    subreddit = account.config.get("subreddit", "test")

    body = {
        "sr": subreddit,
        "title": payload.get("title", "")[:300],
        "kind": "link" if payload.get("link") else "self",
    }

    if payload.get("link"):
        body["url"] = payload["link"]
    else:
        body["text"] = payload.get("text", "")

    resp = httpx.post(
        f"{REDDIT_API}/api/submit",
        headers={
            "Authorization": f"Bearer {account.access_token}",
            "User-Agent": "GSMFWs:v1.0 (by /u/platform_bot)",
        },
        data=body,
        timeout=30,
    )
    resp.raise_for_status()
    result = resp.json()

    post_data = result.get("json", {}).get("data", {})
    job.external_post_id = post_data.get("id", "")
    job.status = "completed"
    job.save(update_fields=["external_post_id", "status"])
    return result
```

## Anti-Patterns
- No `User-Agent` header — Reddit blocks requests silently
- Exceeding self-promotion ratio — account gets shadowbanned
- Posting same content to multiple subreddits simultaneously — spam
- Not handling 429 rate limit responses with backoff

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
