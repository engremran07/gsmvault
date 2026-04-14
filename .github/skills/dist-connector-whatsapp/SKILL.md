---
name: dist-connector-whatsapp
description: "WhatsApp distribution connector. Use when: sending via WhatsApp Business API, template messages, broadcast lists, status updates."
---

# WhatsApp Distribution Connector

## When to Use
- Sending content via WhatsApp Business Cloud API
- Configuring `SocialAccount(channel="whatsapp")` with business credentials
- Sending pre-approved template messages to subscribers
- Broadcasting firmware update notifications

## Rules
- Channel constant: `Channel.WHATSAPP = "whatsapp"`
- WhatsApp Business Cloud API (Meta) — requires approved templates
- Template messages MUST be pre-approved by Meta before sending
- Free-form messages only within 24h of user-initiated conversation
- Rate limit: 80 messages per second (business tier dependent)
- Store `access_token` = permanent token, `config.phone_number_id`

## Patterns

### Sending a Template Message
```python
# apps/distribution/connectors/whatsapp.py
import httpx

WHATSAPP_API = "https://graph.facebook.com/v18.0"

def send_template_message(*, job) -> dict:
    account = job.account
    payload = job.payload or {}
    phone_id = account.config.get("phone_number_id", "")

    body = {
        "messaging_product": "whatsapp",
        "to": payload.get("recipient_phone", ""),
        "type": "template",
        "template": {
            "name": payload.get("template_name", "firmware_update"),
            "language": {"code": "en_US"},
            "components": [{
                "type": "body",
                "parameters": [
                    {"type": "text", "text": payload.get("firmware_name", "")},
                    {"type": "text", "text": payload.get("download_url", "")},
                ],
            }],
        },
    }

    resp = httpx.post(
        f"{WHATSAPP_API}/{phone_id}/messages",
        headers={"Authorization": f"Bearer {account.access_token}"},
        json=body,
        timeout=30,
    )
    resp.raise_for_status()
    result = resp.json()
    job.external_post_id = result.get("messages", [{}])[0].get("id", "")
    job.status = "completed"
    job.save(update_fields=["external_post_id", "status"])
    return result
```

## Anti-Patterns
- Sending free-form messages outside 24h conversation window — blocked
- Using unapproved templates — API rejects with error
- Bulk messaging without opt-in — violates WhatsApp policy
- Storing phone numbers in plaintext logs — PII violation

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
