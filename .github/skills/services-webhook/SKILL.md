---
name: services-webhook
description: "Webhook delivery: WebhookEndpoint, WebhookDelivery, retry logic. Use when: sending webhooks, configuring webhook endpoints, handling delivery failures, webhook signature verification."
---

# Webhook Delivery Patterns

## When to Use
- Notifying external systems of platform events
- Configuring per-user webhook endpoints
- Implementing reliable delivery with retries
- Verifying incoming webhook signatures

## Rules
- Webhook models live in `apps.notifications` (WebhookEndpoint, WebhookDelivery, DeliveryAttempt)
- Deliver webhooks via Celery tasks — never synchronously
- Sign all outgoing webhooks with HMAC-SHA256
- Implement exponential backoff on delivery failures
- Log all delivery attempts (success + failure) for debugging
- Timeout external calls at 10s max — never block indefinitely

## Patterns

### Dispatching a Webhook
```python
# apps/notifications/services.py
import hashlib
import hmac
import json
from .models import WebhookEndpoint, WebhookDelivery

def dispatch_webhook(*, event_type: str, payload: dict) -> list[int]:
    """Queue webhook delivery to all active endpoints for this event."""
    endpoints = WebhookEndpoint.objects.filter(
        is_active=True, events__contains=[event_type]
    )
    delivery_ids = []
    for endpoint in endpoints:
        delivery = WebhookDelivery.objects.create(
            endpoint=endpoint,
            event_type=event_type,
            payload=payload,
            status="pending",
        )
        delivery_ids.append(delivery.pk)
        from .tasks import deliver_webhook
        deliver_webhook.delay(delivery.pk)
    return delivery_ids
```

### Webhook Delivery Task with Retries
```python
# apps/notifications/tasks.py
import hashlib
import hmac
import json
import logging

import requests
from celery import shared_task

logger = logging.getLogger(__name__)

@shared_task(bind=True, max_retries=5, default_retry_delay=30)
def deliver_webhook(self, delivery_id: int) -> None:
    from .models import WebhookDelivery, DeliveryAttempt
    delivery = WebhookDelivery.objects.select_related("endpoint").get(pk=delivery_id)
    endpoint = delivery.endpoint
    payload_json = json.dumps(delivery.payload, default=str)
    signature = hmac.new(
        endpoint.secret.encode(), payload_json.encode(), hashlib.sha256
    ).hexdigest()
    headers = {
        "Content-Type": "application/json",
        "X-Webhook-Signature": f"sha256={signature}",
        "X-Webhook-Event": delivery.event_type,
    }
    try:
        response = requests.post(
            endpoint.url, data=payload_json, headers=headers, timeout=10
        )
        DeliveryAttempt.objects.create(
            delivery=delivery, status_code=response.status_code,
            response_body=response.text[:1000],
        )
        if response.status_code < 400:
            delivery.status = "delivered"
        else:
            delivery.status = "failed"
            raise self.retry(countdown=2 ** self.request.retries * 30)
    except requests.RequestException as exc:
        DeliveryAttempt.objects.create(
            delivery=delivery, status_code=0, response_body=str(exc)[:1000],
        )
        delivery.status = "failed"
        raise self.retry(exc=exc, countdown=2 ** self.request.retries * 30)
    finally:
        delivery.save(update_fields=["status"])
```

### Incoming Webhook Signature Verification
```python
def verify_webhook_signature(
    *, payload: bytes, signature: str, secret: str
) -> bool:
    """Verify HMAC-SHA256 signature on incoming webhook."""
    expected = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
    return hmac.compare_digest(f"sha256={expected}", signature)
```

## Anti-Patterns
- Delivering webhooks synchronously in the request cycle
- No timeout on external HTTP calls — can hang forever
- Missing signature on outgoing webhooks — no integrity verification
- Retrying immediately without backoff — overwhelms failing endpoints

## Red Flags
- `requests.post()` without `timeout` parameter
- No `DeliveryAttempt` logging — impossible to debug failures
- Webhook secret stored in plain text in code

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
