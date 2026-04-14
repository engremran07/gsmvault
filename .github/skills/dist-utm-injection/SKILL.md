---
name: dist-utm-injection
description: "UTM parameter injection for tracking. Use when: adding UTM codes to distributed links, tracking traffic sources, attribution per platform."
---

# UTM Parameter Injection

## When to Use
- Appending UTM parameters to all outbound links in distributed content
- Tracking which platform drives the most traffic
- Attribution for marketing campaigns per channel
- Auto-injecting UTM into `ShareJob.payload` URLs

## Rules
- UTM parameters: `utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term`
- `utm_source` = channel name (twitter, linkedin, facebook, etc.)
- `utm_medium` = `social` for social platforms, `email` for newsletters, `feed` for RSS
- `utm_campaign` = content identifier or campaign slug
- Inject UTM BEFORE sending to connectors — in message-building phase
- Never double-encode UTM params — check if URL already has query string

## Patterns

### UTM Injection Service
```python
# apps/distribution/services.py
from urllib.parse import urlparse, urlencode, parse_qs, urlunparse

def inject_utm(
    *, url: str, source: str, medium: str = "social",
    campaign: str = "", content: str = "",
) -> str:
    """Add UTM parameters to a URL, preserving existing query params."""
    parsed = urlparse(url)
    existing_params = parse_qs(parsed.query)

    utm_params = {
        "utm_source": source,
        "utm_medium": medium,
    }
    if campaign:
        utm_params["utm_campaign"] = campaign
    if content:
        utm_params["utm_content"] = content

    # Don't overwrite existing UTM params
    for key, value in utm_params.items():
        if key not in existing_params:
            existing_params[key] = [value]

    new_query = urlencode(existing_params, doseq=True)
    return urlunparse(parsed._replace(query=new_query))
```

### Auto-Inject in ShareJob Pipeline
```python
def prepare_job_payload(*, job: ShareJob) -> dict:
    """Inject UTM into job payload URLs before sending."""
    payload = job.payload or {}
    if url := payload.get("link"):
        payload["link"] = inject_utm(
            url=url,
            source=job.channel,
            medium="social" if job.channel != "mailchimp" else "email",
            campaign=f"post-{job.post_id}",
        )
    return payload
```

### Medium Mapping
```python
CHANNEL_MEDIUM_MAP = {
    "twitter": "social",
    "linkedin": "social",
    "facebook": "social",
    "telegram": "social",
    "discord": "social",
    "reddit": "social",
    "mailchimp": "email",
    "sendgrid": "email",
    "rss": "feed",
    "atom": "feed",
    "websub": "feed",
}
```

## Anti-Patterns
- UTM params with spaces or special chars — causes tracking failures
- Overwriting existing UTM params on already-tagged URLs
- No `utm_source` — analytics can't attribute traffic source
- Hardcoding UTM values instead of deriving from channel/post

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
