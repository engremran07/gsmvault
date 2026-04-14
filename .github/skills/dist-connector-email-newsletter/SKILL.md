---
name: dist-connector-email-newsletter
description: "Email newsletter distribution. Use when: sending blog digest emails, configuring Mailchimp/SendGrid, newsletter scheduling, subscriber management."
---

# Email Newsletter Distribution

## When to Use
- Sending blog/firmware digest emails to subscribers
- Configuring `SocialAccount(channel="mailchimp"|"sendgrid"|"substack")`
- Scheduling newsletter `ShareJob` for periodic content digests
- Building email content from `ShareTemplate` with placeholders

## Rules
- Channels: `mailchimp`, `sendgrid`, `substack` — each has own connector
- `ShareTemplate(channel="mailchimp")` stores email body template
- Placeholders: `{title}`, `{url}`, `{summary}`, `{hashtags}`
- CAN-SPAM compliance: unsubscribe link MUST be present
- Rate limits: SendGrid 100/sec, Mailchimp varies by plan
- Track sends via `ShareLog` — log delivery and bounce status

## Patterns

### SendGrid Email Sending
```python
# apps/distribution/connectors/email.py
import httpx

SENDGRID_API = "https://api.sendgrid.com/v3/mail/send"

def send_newsletter(*, job) -> dict:
    account = job.account
    payload = job.payload or {}

    body = {
        "personalizations": [{
            "to": [{"email": r} for r in payload.get("recipients", [])],
            "subject": payload.get("subject", ""),
        }],
        "from": {"email": account.config.get("from_email", "noreply@example.com")},
        "content": [{
            "type": "text/html",
            "value": payload.get("html_body", ""),
        }],
    }

    resp = httpx.post(
        SENDGRID_API,
        headers={"Authorization": f"Bearer {account.access_token}"},
        json=body,
        timeout=30,
    )
    resp.raise_for_status()
    job.status = "completed"
    job.save(update_fields=["status"])
    return {"status": "sent", "recipient_count": len(payload.get("recipients", []))}
```

### Building Email from Template
```python
from apps.distribution.models import ShareTemplate

def build_email_content(*, post, template: ShareTemplate) -> str:
    """Render email body from ShareTemplate placeholders."""
    body = template.body_template
    body = body.replace("{title}", post.title)
    body = body.replace("{url}", post.get_absolute_url())
    body = body.replace("{summary}", post.meta_description or "")
    body = body.replace("{hashtags}", ", ".join(post.tag_names()))
    return body
```

## Anti-Patterns
- No unsubscribe link — CAN-SPAM violation
- Sending to recipients without opt-in — spam, deliverability destroyed
- HTML email without plaintext fallback — some clients block HTML
- Not tracking bounces — damages sender reputation

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
