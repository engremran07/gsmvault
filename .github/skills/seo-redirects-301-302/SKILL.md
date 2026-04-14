---
name: seo-redirects-301-302
description: "Redirect management: 301 permanent, 302 temporary. Use when: setting up URL redirects, migrating URLs, handling slug changes, preventing 404 errors."
---

# Redirect Management — 301 & 302

## When to Use

- Setting up permanent (301) or temporary (302) URL redirects
- Migrating old URLs after slug changes
- Preventing 404 errors from external backlinks
- Managing redirect chains and loops

## Rules

### Redirect Model

```python
# apps/seo/models.py
class Redirect(TimestampedModel):
    source_path = models.CharField(max_length=500, unique=True, db_index=True)
    target_path = models.CharField(max_length=500)
    status_code = models.PositiveSmallIntegerField(
        default=301,
        choices=[(301, "301 Permanent"), (302, "302 Temporary")],
    )
    is_active = models.BooleanField(default=True)
    hit_count = models.PositiveIntegerField(default=0)
    last_hit = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "seo_redirect"
        ordering = ["-created_at"]
        verbose_name = "Redirect"
        verbose_name_plural = "Redirects"

    def __str__(self) -> str:
        return f"{self.source_path} → {self.target_path} ({self.status_code})"
```

### When to Use 301 vs 302

| Status | Use Case | SEO Effect |
|--------|----------|------------|
| 301 | Permanent URL change, slug rename, site migration | Passes ~90-99% link equity |
| 302 | Temporary maintenance, A/B test, seasonal redirect | Does NOT pass link equity |
| 308 | Permanent (preserves HTTP method) | Same as 301 for GET |

### Redirect Middleware

```python
# apps/seo/middleware.py
from django.http import HttpResponsePermanentRedirect, HttpResponseRedirect
from django.utils import timezone

class RedirectMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        from apps.seo.models import Redirect
        path = request.path
        redirect = Redirect.objects.filter(
            source_path=path, is_active=True
        ).first()
        if redirect:
            redirect.hit_count += 1
            redirect.last_hit = timezone.now()
            redirect.save(update_fields=["hit_count", "last_hit"])
            if redirect.status_code == 301:
                return HttpResponsePermanentRedirect(redirect.target_path)
            return HttpResponseRedirect(redirect.target_path)
        return self.get_response(request)
```

### Chain Detection Service

```python
# apps/seo/services.py
def detect_redirect_chains(max_depth: int = 5) -> list[list[str]]:
    """Find redirect chains longer than 1 hop."""
    from apps.seo.models import Redirect
    chains: list[list[str]] = []
    for r in Redirect.objects.filter(is_active=True):
        chain = [r.source_path]
        target = r.target_path
        depth = 0
        while depth < max_depth:
            next_r = Redirect.objects.filter(
                source_path=target, is_active=True
            ).first()
            if not next_r:
                break
            chain.append(next_r.source_path)
            target = next_r.target_path
            depth += 1
        if len(chain) > 1:
            chain.append(target)
            chains.append(chain)
    return chains
```

### Auto-Redirect on Slug Change

```python
def create_redirect_on_slug_change(
    old_path: str, new_path: str
) -> None:
    """Create a 301 redirect when a model's slug changes."""
    from apps.seo.models import Redirect
    if old_path != new_path:
        Redirect.objects.update_or_create(
            source_path=old_path,
            defaults={"target_path": new_path, "status_code": 301, "is_active": True},
        )
```

## Anti-Patterns

- Redirect chains (A→B→C) — flatten to A→C
- Redirect loops (A→B→A) — validate before saving
- Using 302 for permanent changes — loses link equity
- No `hit_count` tracking — can't identify stale redirects

## Red Flags

- Middleware queries DB on every request without caching
- No loop detection before saving a redirect
- Chain depth exceeds 3 hops
- 302 used where 301 is appropriate

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
