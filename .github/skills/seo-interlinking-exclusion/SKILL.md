---
name: seo-interlinking-exclusion
description: "Link exclusion rules: nofollow, noindex, excluded paths. Use when: marking links as nofollow, excluding pages from internal linking, managing link equity flow."
---

# Link Exclusion Rules

## When to Use

- Marking specific links as `rel="nofollow"` or `rel="ugc"`
- Excluding pages from the internal linking engine
- Controlling link equity flow across the site

## Rules

### Exclusion Patterns in LinkableEntity

```python
# apps/seo/models.py
class LinkableEntity(TimestampedModel):
    path = models.CharField(max_length=500, unique=True)
    title = models.CharField(max_length=300)
    is_linkable = models.BooleanField(default=True)       # Can be linked TO
    is_link_source = models.BooleanField(default=True)     # Can link FROM
    nofollow = models.BooleanField(default=False)          # rel="nofollow"
    exclude_paths = models.JSONField(default=list, blank=True)  # paths to never link to
```

### Exclusion Check in Service

```python
# apps/seo/services.py
EXCLUDED_PATH_PREFIXES = [
    "/admin/",
    "/api/",
    "/accounts/login/",
    "/accounts/register/",
    "/consent/",
]

def should_exclude_link(source_path: str, target_path: str) -> bool:
    """Check if a link should be excluded."""
    # Never link to excluded prefixes
    for prefix in EXCLUDED_PATH_PREFIXES:
        if target_path.startswith(prefix):
            return True
    # Never self-link
    if source_path == target_path:
        return True
    return False
```

### Rel Attribute Rules

| Link Type | `rel` Attribute | When |
|-----------|----------------|------|
| Internal editorial | (none) | Default for approved links |
| User-generated | `ugc nofollow` | Forum posts, comments |
| Sponsored/affiliate | `sponsored nofollow` | Affiliate links |
| External untrusted | `nofollow noopener` | Unknown external domains |
| Internal admin/auth | Excluded entirely | Never auto-link |

### Applying Nofollow in Injection

```python
def build_link_tag(url: str, text: str, nofollow: bool = False) -> str:
    rel = ' rel="nofollow"' if nofollow else ""
    return f'<a href="{url}"{rel}>{text}</a>'
```

### Admin Exclusion Controls

```python
# apps/seo/admin.py
@admin.register(LinkableEntity)
class LinkableEntityAdmin(admin.ModelAdmin["LinkableEntity"]):
    list_display = ["path", "title", "is_linkable", "nofollow"]
    list_filter = ["is_linkable", "nofollow"]
    list_editable = ["is_linkable", "nofollow"]
    search_fields = ["path", "title"]
```

## Anti-Patterns

- Blanket `nofollow` on all internal links — wastes link equity
- No exclusion list — linking to login/admin pages
- Hardcoding exclusions in templates — use model flags instead
- Self-links — pages linking to themselves

## Red Flags

- `/admin/` or `/api/` paths appear as link targets
- Self-referencing links in injected content
- Missing `rel="ugc"` on user-generated links
- No way to toggle `is_linkable` per entity

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
