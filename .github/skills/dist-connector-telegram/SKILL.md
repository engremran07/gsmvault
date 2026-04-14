---
name: dist-connector-telegram
description: "Telegram distribution connector. Use when: posting to Telegram channels/groups, Bot API, sending messages with media, formatting with Markdown."
---

# Telegram Distribution Connector

## When to Use
- Publishing content to Telegram channels via Bot API
- Configuring `SocialAccount(channel="telegram")` with bot token + chat ID
- Sending formatted messages with images, links, and buttons
- Scheduling Telegram posts via `ShareJob`

## Rules
- Channel constant: `Channel.TELEGRAM = "telegram"`
- Uses Telegram Bot API — bot must be admin of the channel
- Store `access_token` = bot token, `config.chat_id` = channel ID
- Message limit: 4096 characters with Markdown/HTML formatting
- Rate limit: 30 messages per second to different chats
- Media: photos, documents, videos via separate endpoints

## Patterns

### Sending a Channel Message
```python
# apps/distribution/connectors/telegram.py
import httpx

TELEGRAM_API = "https://api.telegram.org"

def send_message(*, job) -> dict:
    account = job.account
    payload = job.payload or {}
    bot_token = account.access_token
    chat_id = account.config.get("chat_id", "")

    text = payload.get("text", "")[:4096]
    body = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": "HTML",
        "disable_web_page_preview": not payload.get("show_preview", True),
    }

    resp = httpx.post(
        f"{TELEGRAM_API}/bot{bot_token}/sendMessage",
        json=body,
        timeout=30,
    )
    resp.raise_for_status()
    result = resp.json()
    job.external_post_id = str(result["result"]["message_id"])
    job.status = "completed"
    job.save(update_fields=["external_post_id", "status"])
    return result
```

### Sending Photo with Caption
```python
def send_photo(*, job) -> dict:
    account = job.account
    payload = job.payload or {}
    bot_token = account.access_token
    chat_id = account.config.get("chat_id", "")

    body = {
        "chat_id": chat_id,
        "photo": payload.get("image_url", ""),
        "caption": payload.get("text", "")[:1024],
        "parse_mode": "HTML",
    }
    resp = httpx.post(
        f"{TELEGRAM_API}/bot{bot_token}/sendPhoto",
        json=body,
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()
```

## Anti-Patterns
- Using user account tokens — must be bot tokens via `@BotFather`
- Exceeding 30 msg/s rate limit — bot gets temporarily banned
- Not handling `429 Too Many Requests` with backoff
- Sending unformatted plain text when HTML is supported

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
