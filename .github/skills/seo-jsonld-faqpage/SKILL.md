---
name: seo-jsonld-faqpage
description: "JSON-LD FAQPage schema. Use when: adding FAQ structured data, building FAQ sections with rich snippets, forum FAQ entries."
---

# JSON-LD FAQPage Schema

## When to Use

- Adding FAQ rich snippets to pages with Q&A content
- Building FAQ sections on product/firmware pages
- Structured data for `ForumFAQEntry` records

## Rules

### Schema Structure

```python
# apps/seo/services.py
def build_faqpage_schema(
    faqs: list[dict[str, str]],
    page_url: str,
) -> dict:
    """Build JSON-LD FAQPage. Each FAQ dict has 'question' and 'answer'."""
    return {
        "@context": "https://schema.org",
        "@type": "FAQPage",
        "mainEntity": [
            {
                "@type": "Question",
                "name": faq["question"],
                "acceptedAnswer": {
                    "@type": "Answer",
                    "text": faq["answer"],
                },
            }
            for faq in faqs
            if faq.get("question") and faq.get("answer")
        ],
    }
```

### Usage from Forum FAQ Entries

```python
def build_forum_faq_schema(topic_id: int, site_url: str) -> dict | None:
    """Build FAQPage schema from ForumFAQEntry records."""
    from apps.forum.models import ForumFAQEntry
    entries = ForumFAQEntry.objects.filter(topic_id=topic_id).values("question", "answer")
    faqs = [{"question": e["question"], "answer": e["answer"]} for e in entries]
    if not faqs:
        return None
    return build_faqpage_schema(faqs, f"{site_url}/forum/t/{topic_id}/")
```

### Google Requirements

| Constraint | Rule |
|-----------|------|
| Min questions | At least 1 Q&A pair |
| Answer format | Plain text or limited HTML |
| No advertising | Answers must not be promotional |
| Visibility | FAQ must be visible on page |
| Uniqueness | Same FAQ not on multiple pages |

### Template Pattern

```html
{% if faq_schema %}
<script type="application/ld+json">{{ faq_schema|safe }}</script>
{% endif %}

{# Visible FAQ section must match structured data #}
<div class="faq-section">
{% for faq in faqs %}
  <details>
    <summary>{{ faq.question }}</summary>
    <p>{{ faq.answer }}</p>
  </details>
{% endfor %}
</div>
```

## Anti-Patterns

- Adding FAQPage schema without visible FAQ on page — Google will penalize
- More than 10 FAQs per page — diminishing returns, clutters SERP
- Using HTML in answer text without sanitization — always `sanitize_html_content()`

## Red Flags

- Empty `mainEntity` array (no Q&A pairs)
- FAQ answers contain `<script>` or event handlers
- Same FAQ schema duplicated across multiple pages

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
