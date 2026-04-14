---
name: seo-audit-engine
description: "21-check SEO audit engine: meta, headings, images, links, performance. Use when: building page-level SEO audits, health checks, or content quality scanners."
---

# SEO Audit Engine

## When to Use

- Building a per-page SEO audit that scores content quality
- Adding automated checks for missing meta, broken links, heading hierarchy
- Creating admin dashboard SEO health reports

## Rules

### 21-Check Registry

| # | Check | Target | Severity |
|---|-------|--------|----------|
| 1 | Title exists | `Metadata.title` | critical |
| 2 | Title length 30–60 chars | `Metadata.title` | warning |
| 3 | Meta description exists | `Metadata.description` | critical |
| 4 | Description length 120–160 chars | `Metadata.description` | warning |
| 5 | H1 exists and is unique | Page HTML | critical |
| 6 | Heading hierarchy (no skips) | H1→H2→H3 | warning |
| 7 | Images have alt text | `<img>` tags | warning |
| 8 | Images have width/height | `<img>` tags | info |
| 9 | Internal links present | `<a>` hrefs | warning |
| 10 | No broken internal links | `<a>` hrefs | critical |
| 11 | Canonical URL set | `<link rel="canonical">` | critical |
| 12 | OG title exists | `og:title` meta | warning |
| 13 | OG description exists | `og:description` meta | warning |
| 14 | OG image exists | `og:image` meta | warning |
| 15 | JSON-LD schema present | `<script type="application/ld+json">` | warning |
| 16 | No duplicate titles across pages | `Metadata` table | critical |
| 17 | No duplicate descriptions | `Metadata` table | critical |
| 18 | robots meta not noindex (unless intended) | `<meta name="robots">` | warning |
| 19 | Page in sitemap | `SitemapEntry` | warning |
| 20 | No orphan pages (has inbound links) | `LinkSuggestion` | info |
| 21 | Page load size < 3MB | Response size | info |

### Service Pattern

```python
# apps/seo/services.py
from dataclasses import dataclass

@dataclass
class AuditResult:
    check_id: int
    name: str
    passed: bool
    severity: str  # critical | warning | info
    message: str

def audit_page(url: str, metadata: "Metadata | None") -> list[AuditResult]:
    results: list[AuditResult] = []
    # Check 1: Title exists
    if not metadata or not metadata.title:
        results.append(AuditResult(1, "title_exists", False, "critical", "Missing page title"))
    else:
        results.append(AuditResult(1, "title_exists", True, "critical", ""))
        # Check 2: Title length
        length = len(metadata.title)
        passed = 30 <= length <= 60
        results.append(AuditResult(2, "title_length", passed, "warning", f"Title is {length} chars"))
    return results
```

## Anti-Patterns

- Running audit checks in views — always use `services.py`
- Hardcoding check thresholds — use `SEOSettings` singleton for configurable limits
- Importing `Metadata` in other apps' `services.py` — audit lives in `apps.seo` only

## Red Flags

- `severity` not in `("critical", "warning", "info")`
- Audit results stored without timestamp — always include `audited_at`
- Missing `select_related` when loading Metadata with FK joins

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
