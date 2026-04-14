---
name: seo-keyword-intent-classification
description: "Search intent classification: informational, transactional, navigational. Use when: categorizing keywords by user intent, tailoring content strategy, mapping intent to page types."
---

# Keyword Intent Classification

## When to Use

- Categorizing keywords by search intent (informational/transactional/navigational)
- Mapping intent to content type and page structure
- Prioritizing keywords by commercial value
- Building intent-aware meta descriptions

## Rules

### Intent Categories

| Intent | Signal Words | Page Type | Example |
|--------|-------------|-----------|---------|
| Informational | how, what, why, guide, tutorial | Blog/FAQ | "how to flash firmware" |
| Transactional | download, buy, free, get, install | Product/Download | "download Samsung firmware" |
| Navigational | brand name, site name, login | Landing/Brand | "GSMFWs Samsung" |
| Commercial Investigation | best, review, compare, vs | Comparison/Review | "best firmware tool 2025" |

### Intent Classifier Service

```python
# apps/seo/services.py
import re

INTENT_PATTERNS: dict[str, list[str]] = {
    "informational": [
        r"\bhow\b", r"\bwhat\b", r"\bwhy\b", r"\bguide\b",
        r"\btutorial\b", r"\bexplain\b", r"\blearn\b",
    ],
    "transactional": [
        r"\bdownload\b", r"\bbuy\b", r"\bfree\b", r"\bget\b",
        r"\binstall\b", r"\bprice\b", r"\bcoupon\b",
    ],
    "navigational": [
        r"\blogin\b", r"\bsign.?in\b", r"\baccount\b",
        r"\bdashboard\b", r"\bofficial\b",
    ],
    "commercial": [
        r"\bbest\b", r"\breview\b", r"\bcompare\b",
        r"\bvs\b", r"\btop\s+\d+\b", r"\balternativ\b",
    ],
}

def classify_intent(keyword: str) -> str:
    """Classify a keyword by search intent."""
    keyword_lower = keyword.lower()
    scores: dict[str, int] = {k: 0 for k in INTENT_PATTERNS}
    for intent, patterns in INTENT_PATTERNS.items():
        for pattern in patterns:
            if re.search(pattern, keyword_lower):
                scores[intent] += 1
    best = max(scores, key=scores.get)  # type: ignore[arg-type]
    if scores[best] == 0:
        return "informational"  # default
    return best
```

### Intent Field on TrackedKeyword

```python
class TrackedKeyword(TimestampedModel):
    # ... existing fields ...
    intent = models.CharField(
        max_length=20,
        choices=[
            ("informational", "Informational"),
            ("transactional", "Transactional"),
            ("navigational", "Navigational"),
            ("commercial", "Commercial Investigation"),
        ],
        default="informational",
    )
```

### Auto-Classification on Save

```python
def save(self, *args, **kwargs):
    if not self.intent or self.intent == "informational":
        self.intent = classify_intent(self.keyword)
    super().save(*args, **kwargs)
```

### Intent-Aware Meta Generation

| Intent | Title Pattern | Description Focus |
|--------|--------------|-------------------|
| Informational | "How to {action} — Guide" | Explain, teach, list steps |
| Transactional | "Download {product} Free" | CTA, availability, file size |
| Navigational | "{Brand} — Official {Page}" | Brand, trust, authority |
| Commercial | "Best {product} — {year} Review" | Comparison, pros/cons |

## Anti-Patterns

- Treating all keywords as transactional — misaligns content with user needs
- No default intent — unclassified keywords cause errors
- Classifying at query time instead of save time — wasteful

## Red Flags

- Intent classification missing from keyword model
- No signal word patterns — classification is random
- Hard-coded intent without override capability
- Intent not used in meta generation pipeline

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
