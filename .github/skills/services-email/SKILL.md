---
name: services-email
description: "Email sending: EmailTemplate, EmailQueue, SMTP configuration. Use when: sending transactional emails, email templates, queued email delivery, email bounces."
---

# Email Service Patterns

## When to Use
- Transactional emails (password reset, verification, order confirmation)
- Templated emails with dynamic content
- Queued email delivery via Celery
- Handling bounces and delivery failures

## Rules
- Email models live in `apps.notifications` (EmailTemplate, EmailQueue, EmailBounce)
- Never send emails synchronously in the request cycle — always queue via Celery
- Use `EmailTemplate` model for admin-editable email content
- Track delivery status in `EmailQueue` (pending, sent, failed, bounced)
- Never log email content containing sensitive data

## Patterns

### Queuing an Email
```python
# apps/notifications/services.py
from .models import EmailTemplate, EmailQueue

def queue_email(
    *,
    to_email: str,
    template_name: str,
    context: dict,
    user_id: int | None = None,
) -> EmailQueue:
    """Queue an email for async delivery."""
    template = EmailTemplate.objects.get(name=template_name, is_active=True)
    subject = template.render_subject(context)
    body_html = template.render_body(context)
    return EmailQueue.objects.create(
        to_email=to_email,
        subject=subject,
        body_html=body_html,
        template=template,
        user_id=user_id,
        status="pending",
    )
```

### Celery Task for Delivery
```python
# apps/notifications/tasks.py
import logging
from celery import shared_task
from django.core.mail import send_mail
from django.conf import settings

logger = logging.getLogger(__name__)

@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def deliver_email(self, email_queue_id: int) -> None:
    from .models import EmailQueue
    email = EmailQueue.objects.get(pk=email_queue_id)
    try:
        send_mail(
            subject=email.subject,
            message="",  # Plain text fallback
            html_message=email.body_html,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email.to_email],
            fail_silently=False,
        )
        email.status = "sent"
        email.save(update_fields=["status"])
    except Exception as exc:
        logger.exception("Email delivery failed for queue %s", email_queue_id)
        email.status = "failed"
        email.retry_count += 1
        email.save(update_fields=["status", "retry_count"])
        raise self.retry(exc=exc)
```

### Templated Email with Service
```python
def send_templated_email(
    *, user_id: int, template_name: str, context: dict
) -> None:
    """Queue a templated email to a user."""
    from apps.users.models import User
    user = User.objects.get(pk=user_id)
    email = queue_email(
        to_email=user.email,
        template_name=template_name,
        context={**context, "user_name": user.get_full_name()},
        user_id=user_id,
    )
    deliver_email.delay(email.pk)
```

### Process Email Queue (Batch)
```python
@shared_task
def process_email_queue() -> int:
    """Process all pending emails in the queue."""
    pending = EmailQueue.objects.filter(
        status="pending", retry_count__lt=3
    ).order_by("created_at")[:100]
    sent = 0
    for email in pending:
        deliver_email.delay(email.pk)
        sent += 1
    return sent
```

## Anti-Patterns
- `send_mail()` directly in views — blocks the response
- Hardcoded email subjects/bodies — use `EmailTemplate` model
- No retry logic on delivery failures
- Sending to unverified email addresses without rate limiting

## Red Flags
- `send_mail()` call without Celery wrapping
- Missing `status` tracking on queued emails
- No bounce handling for failed deliveries

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
