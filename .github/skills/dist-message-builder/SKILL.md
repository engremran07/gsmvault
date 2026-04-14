---
name: dist-message-builder
description: "Message building from templates and variants. Use when: constructing platform-specific messages, rendering ShareTemplate, generating ContentVariant payloads."
---

# Message Builder

## When to Use
- Building platform-specific messages from `ShareTemplate`
- Generating `ContentVariant` records (summary, caption, thread, etc.)
- Adapting content for each channel's format constraints
- Using AI prompts to generate optimized social content

## Rules
- `ShareTemplate.body_template` uses placeholders: `{title}`, `{url}`, `{summary}`, `{hashtags}`
- Templates are channel-specific: `ShareTemplate(channel="twitter")` differs from `channel="linkedin"`
- `ContentVariant.VARIANT_TYPES`: summary, caption, tags, image_prompt, video_script, thread, email
- `ContentVariant.payload` is a JSON field — structure varies by variant type
- AI-generated variants use `ShareTemplate.ai_prompt` as the system prompt
- Each channel has character limits — message builder enforces truncation

## Patterns

### Rendering a Template
```python
# apps/distribution/services.py
from apps.distribution.models import ShareTemplate

CHANNEL_LIMITS = {
    "twitter": 280,
    "linkedin": 1300,
    "facebook": 63206,
    "telegram": 4096,
    "discord": 2000,
    "pinterest": 500,
    "reddit": 40000,
}

def render_message(
    *, template: ShareTemplate, post, extra_context: dict | None = None,
) -> str:
    """Render a ShareTemplate with post data, respecting channel limits."""
    context = {
        "title": post.title,
        "url": post.get_absolute_url(),
        "summary": post.meta_description or "",
        "hashtags": " ".join(f"#{t}" for t in post.tag_names()),
    }
    if extra_context:
        context.update(extra_context)

    message = template.body_template
    for key, value in context.items():
        message = message.replace(f"{{{key}}}", str(value))

    # Enforce channel character limit
    limit = CHANNEL_LIMITS.get(template.channel, 5000)
    return message[:limit]
```

### Generating Content Variants
```python
from apps.distribution.models import ContentVariant

def generate_variants(*, post, channels: list[str]) -> list[ContentVariant]:
    """Generate content variants for each target channel."""
    variants = []
    for channel in channels:
        template = ShareTemplate.objects.filter(
            channel=channel, is_default=True,
        ).first()
        if not template:
            continue
        text = render_message(template=template, post=post)
        variant = ContentVariant.objects.create(
            post=post,
            channel=channel,
            variant_type="caption",
            payload={"text": text, "char_count": len(text)},
        )
        variants.append(variant)
    return variants
```

## Anti-Patterns
- Sending the same message to all platforms without adaptation
- Ignoring character limits — posts get silently truncated or rejected
- Not using templates — hardcoding message format in connectors
- Missing placeholder values showing `{title}` literally in posts

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
