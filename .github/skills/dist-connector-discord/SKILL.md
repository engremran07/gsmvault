---
name: dist-connector-discord
description: "Discord distribution connector. Use when: posting to Discord channels via webhooks, bot API, embedding rich content, server notifications."
---

# Discord Distribution Connector

## When to Use
- Posting content to Discord channels via webhooks or Bot API
- Configuring `SocialAccount(channel="discord")` with webhook URL
- Sending rich embeds with firmware info, blog posts
- Server notification for new firmware releases

## Rules
- Channel constant: `Channel.DISCORD = "discord"`
- Preferred method: Webhooks (no bot required, simpler)
- `access_token` = webhook URL for webhook mode
- Embeds support: title, description, URL, color, thumbnail, fields, footer
- Rate limit: 5 requests per 2 seconds per webhook
- Message limit: 2000 chars text, 10 embeds per message

## Patterns

### Sending via Webhook
```python
# apps/distribution/connectors/discord.py
import httpx

def send_webhook(*, job) -> dict:
    account = job.account
    payload = job.payload or {}
    webhook_url = account.access_token  # Webhook URL stored as token

    body = {
        "content": payload.get("text", "")[:2000],
        "embeds": [{
            "title": payload.get("title", ""),
            "description": payload.get("summary", "")[:4096],
            "url": payload.get("link", ""),
            "color": 0x00D4AA,  # Accent color
            "thumbnail": {"url": payload.get("image_url", "")},
            "footer": {"text": "GSMFWs Platform"},
        }] if payload.get("title") else [],
    }

    resp = httpx.post(webhook_url, json=body, timeout=30)
    resp.raise_for_status()
    job.status = "completed"
    job.save(update_fields=["status"])
    return {"status": "sent"}
```

### Firmware Release Embed
```python
def build_firmware_embed(*, firmware) -> dict:
    return {
        "title": f"New Firmware: {firmware.name}",
        "description": firmware.description[:4096] if firmware.description else "",
        "url": firmware.get_absolute_url(),
        "color": 0x00D4AA,
        "fields": [
            {"name": "Brand", "value": firmware.brand.name, "inline": True},
            {"name": "Model", "value": firmware.model.name, "inline": True},
            {"name": "Size", "value": firmware.file_size_display, "inline": True},
        ],
        "footer": {"text": f"Uploaded {firmware.created_at:%Y-%m-%d}"},
    }
```

## Anti-Patterns
- Exceeding 5 requests per 2 seconds — webhook gets rate-limited/disabled
- Embeds with all fields empty — renders as blank card
- Using bot tokens when webhooks suffice — unnecessary complexity
- Not validating webhook URL format before storing

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
