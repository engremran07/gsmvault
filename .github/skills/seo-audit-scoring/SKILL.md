---
name: seo-audit-scoring
description: "SEO scoring system: per-page score, overall health. Use when: computing SEO scores, building health dashboards, grading content quality."
---

# SEO Audit Scoring

## When to Use

- Computing a 0–100 SEO score per page
- Building site-wide health dashboards in admin
- Grading content before publish (editorial workflow)

## Rules

### Scoring Formula

```python
# apps/seo/services.py
from apps.seo.models import Metadata

WEIGHTS: dict[str, int] = {
    "critical": 10,
    "warning": 5,
    "info": 1,
}

def calculate_page_score(audit_results: list["AuditResult"]) -> int:
    """Return 0–100 score. Higher = better SEO health."""
    max_points = sum(WEIGHTS[r.severity] for r in audit_results)
    if max_points == 0:
        return 100
    earned = sum(WEIGHTS[r.severity] for r in audit_results if r.passed)
    return round((earned / max_points) * 100)

def get_score_grade(score: int) -> str:
    """Map score to letter grade."""
    if score >= 90:
        return "A"
    if score >= 75:
        return "B"
    if score >= 60:
        return "C"
    if score >= 40:
        return "D"
    return "F"
```

### Score Thresholds

| Grade | Range | Color Token | Action |
|-------|-------|-------------|--------|
| A | 90–100 | `--color-success` | No action needed |
| B | 75–89 | `--color-success` | Minor improvements |
| C | 60–74 | `--color-warning` | Review recommended |
| D | 40–59 | `--color-warning` | Significant issues |
| F | 0–39 | `--color-error` | Critical — fix before publish |

### Site Health Aggregation

```python
def calculate_site_health(page_scores: list[int]) -> dict[str, int | float]:
    """Aggregate per-page scores into site health metrics."""
    if not page_scores:
        return {"average": 0, "min": 0, "max": 0, "pages_audited": 0}
    return {
        "average": round(sum(page_scores) / len(page_scores)),
        "min": min(page_scores),
        "max": max(page_scores),
        "pages_audited": len(page_scores),
        "critical_pages": sum(1 for s in page_scores if s < 40),
    }
```

### Admin Display Pattern

```python
# In admin view context
context["seo_score"] = calculate_page_score(results)
context["seo_grade"] = get_score_grade(context["seo_score"])
```

```html
{% include "components/_admin_kpi_card.html" with title="SEO Score" value=seo_score suffix="/100" %}
```

## Anti-Patterns

- Storing scores in `Metadata` model — compute on demand or cache with TTL
- Using raw percentages without grade mapping — always show letter grades in UI
- Weighting all checks equally — critical checks must outweigh info checks

## Red Flags

- Score exceeds 100 or goes below 0
- No distinction between critical and info severity in weight calculation
- Caching scores without invalidation on content change

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
