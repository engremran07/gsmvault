---
name: seo-robots-crawl-delay
description: "Crawl-delay directive management. Use when: configuring per-bot crawl rates, managing server load from crawlers, throttling aggressive bots."
---

# Crawl-Delay Directive Management

## When to Use

- Throttling aggressive crawlers to reduce server load
- Setting per-bot crawl rates in robots.txt
- Coordinating with `apps.security` CrawlerRule for enforcement

## Rules

### robots.txt Crawl-Delay Pattern

```python
# apps/seo/services.py
def build_robots_rules(
    default_delay: int = 0,
    bot_delays: dict[str, int] | None = None,
) -> str:
    """Build robots.txt bot-specific rules with crawl-delay."""
    bot_delays = bot_delays or {
        "AhrefsBot": 10,
        "SemrushBot": 10,
        "MJ12bot": 30,
        "DotBot": 30,
        "BLEXBot": 60,
    }
    lines: list[str] = []
    # Default rule
    lines.extend(["User-agent: *", "Allow: /"])
    if default_delay:
        lines.append(f"Crawl-delay: {default_delay}")
    lines.append("")
    # Per-bot rules
    for bot, delay in bot_delays.items():
        lines.extend([
            f"User-agent: {bot}",
            f"Crawl-delay: {delay}",
            "",
        ])
    return "\n".join(lines)
```

### Database-Driven Delays

```python
def get_crawl_delays_from_db() -> dict[str, int]:
    """Load bot crawl delays from SEOSettings or CrawlerRule."""
    from apps.seo.models import SEOSettings
    settings = SEOSettings.get_solo()
    # Parse stored JSON or return defaults
    import json
    try:
        return json.loads(settings.crawl_delay_config or "{}")
    except json.JSONDecodeError:
        return {}
```

### Common Bot Delay Values

| Bot | Recommended Delay | Reason |
|-----|-------------------|--------|
| Googlebot | 0 (none) | Never throttle Google |
| Bingbot | 0–1 | Low delay acceptable |
| AhrefsBot | 10 | Aggressive SEO crawler |
| SemrushBot | 10 | SEO analysis bot |
| MJ12bot | 30 | Majestic backlink crawler |
| DotBot | 30 | Moz crawler |
| BLEXBot | 60 | Webmaster tools bot |

### Integration with CrawlerRule

```python
# robots.txt crawl-delay is advisory. For enforcement, use apps.security.
# CrawlerRule model enforces actual rate limits at middleware level.
# robots.txt = polite request | CrawlerRule = hard enforcement
```

### Validation

```python
def validate_crawl_delays(delays: dict[str, int]) -> list[str]:
    errors = []
    for bot, delay in delays.items():
        if delay < 0:
            errors.append(f"{bot}: delay cannot be negative")
        if delay > 120:
            errors.append(f"{bot}: delay > 120s is excessive")
        if bot.lower() == "googlebot" and delay > 0:
            errors.append("Never set Crawl-delay for Googlebot")
    return errors
```

## Anti-Patterns

- Setting `Crawl-delay` for Googlebot — Google ignores it and may penalize
- Relying solely on `Crawl-delay` for enforcement — use `CrawlerRule` in `apps.security`
- Excessive delays (>120s) — bots may give up and not crawl at all

## Red Flags

- Negative crawl delay values
- Same User-agent block appears multiple times
- Missing `Allow: /` in default User-agent block

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
