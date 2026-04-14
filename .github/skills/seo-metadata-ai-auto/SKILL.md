---
name: seo-metadata-ai-auto
description: "AI-powered automatic meta generation. Use when: auto-generating titles/descriptions with AI, configuring SeoAutomationSettings, building AI meta pipelines."
---

# AI-Powered Automatic Meta Generation

## When to Use

- Auto-generating SEO titles and descriptions from page content
- Configuring `SeoAutomationSettings` for AI meta generation
- Building Celery tasks for batch AI meta generation

## Rules

### Configuration Model

```python
# apps/seo/models.py — SeoAutomationSettings (django-solo singleton)
# ai_meta_enabled: BooleanField (toggle AI generation)
# ai_provider: CharField (openai | anthropic | local)
# auto_generate_on_publish: BooleanField
# max_title_length: IntegerField (default=60)
# max_description_length: IntegerField (default=155)
```

### AI Generation Service

```python
# apps/seo/services.py
from apps.core.ai import CoreAiService

def ai_generate_meta(content: str, content_type: str = "page") -> dict[str, str]:
    """Generate title + description using AI. Returns dict with 'title' and 'description'."""
    from apps.seo.models import SeoAutomationSettings
    settings = SeoAutomationSettings.get_solo()
    if not settings.ai_meta_enabled:
        return {}

    prompt = (
        f"Generate an SEO title (max {settings.max_title_length} chars) "
        f"and meta description (max {settings.max_description_length} chars) "
        f"for this {content_type} content. Return JSON with 'title' and 'description' keys.\n\n"
        f"Content:\n{content[:2000]}"
    )
    result = CoreAiService.generate_text(prompt, response_format="json")
    return _parse_ai_meta_response(result, settings)

def _parse_ai_meta_response(
    raw: str, settings: "SeoAutomationSettings"
) -> dict[str, str]:
    """Parse and validate AI response, enforce length limits."""
    import json
    try:
        data = json.loads(raw)
    except (json.JSONDecodeError, TypeError):
        return {}
    title = str(data.get("title", ""))[:settings.max_title_length]
    description = str(data.get("description", ""))[:settings.max_description_length]
    return {"title": title, "description": description}
```

### Celery Task for Batch Generation

```python
# apps/seo/tasks.py
from celery import shared_task

@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def generate_missing_meta(self: "Task") -> dict[str, int]:
    """Generate AI meta for pages missing title or description."""
    from apps.seo.models import Metadata
    from apps.seo.services import ai_generate_meta
    missing = Metadata.objects.filter(title="") | Metadata.objects.filter(description="")
    generated = 0
    for meta in missing[:50]:  # Batch limit
        result = ai_generate_meta(meta.content_preview or "")
        if result:
            meta.title = result.get("title", meta.title)
            meta.description = result.get("description", meta.description)
            meta.save(update_fields=["title", "description"])
            generated += 1
    return {"generated": generated, "remaining": missing.count() - generated}
```

## Anti-Patterns

- Calling AI in request/response cycle — always use Celery tasks for batch
- Trusting AI output without length validation — always truncate
- No fallback when AI is disabled — generate from content directly

## Red Flags

- `ai_meta_enabled` checked in views instead of service
- AI prompt includes user-supplied data without sanitization
- No rate limiting on AI API calls

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
