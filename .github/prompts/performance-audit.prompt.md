---
agent: 'agent'
description: 'Audit performance including N+1 queries, database indexes, caching, response times, and static file optimization'
tools: ['semantic_search', 'read_file', 'grep_search', 'file_search', 'run_in_terminal']
---

# Performance Audit

Identify performance bottlenecks across queries, caching, static assets, and response handling in the GSMFWs platform.

## 1 — N+1 Query Detection

### select_related Missing
Grep `apps/*/views*.py` and `apps/*/services*.py` for querysets that access FK fields without `select_related()`:

Pattern: A view iterates a queryset and accesses `.foreignkey_field.attribute` inside a loop without prior `select_related("foreignkey_field")`.

```python
# N+1 PROBLEM
topics = ForumTopic.objects.all()
for topic in topics:
    print(topic.author.username)  # Extra query per iteration!

# FIX
topics = ForumTopic.objects.select_related("author").all()
```

### prefetch_related Missing
Check for reverse FK or M2M access in loops without `prefetch_related()`:

```python
# N+1 PROBLEM
for category in categories:
    topics = category.topics.all()  # Extra query per category!

# FIX
categories = ForumCategory.objects.prefetch_related("topics").all()
```

### Serializer Depth
In DRF serializers, nested serializers accessing related models without queryset optimization cause N+1. Check `apps/*/api.py` viewsets that their `get_queryset()` uses appropriate `select_related` / `prefetch_related`.

## 2 — Database Index Audit

### Missing Indexes
For each model, check fields used in:
- `filter()` conditions — should have `db_index=True`
- `order_by()` — should have index
- Unique lookups — should have `unique=True` or index
- FK fields — auto-indexed, verify
- Composite queries — may need multi-column `Index` in Meta

### Unused Indexes
Check for indexes on fields never used in queries (wastes write performance).

### Full-Text Search
If `SearchVector` / `SearchQuery` is used, verify GIN index exists on the search column.

## 3 — Cache Strategy

### DistributedCacheManager Usage
Check if `apps/core/cache.py` `DistributedCacheManager` is used for:
- Frequently accessed settings (`SiteSettings`)
- Category lists
- Leaderboard data
- SEO metadata

### Cache Invalidation
Verify cache keys are invalidated when underlying data changes. Check for stale cache patterns.

### Per-View Caching
Identify views with heavy queries that could benefit from `@cache_page()` decoration. Check that:
- Authenticated views DON'T use cache_page without vary_on_headers
- Public listing pages DO have appropriate cache
- Cache TTL is reasonable (not too long for dynamic content)

### Template Fragment Caching
Check for `{% cache %}` template tag usage on expensive template blocks (sidebar stats, navigation, footer).

## 4 — Response Time Optimization

### Slow Views
Identify views with complex query chains that could be optimized:
- Multiple sequential queries that could be combined
- Python-level filtering that could be pushed to database
- Aggregations computed in Python instead of `.annotate()` / `.aggregate()`

### Pagination
Verify list views use pagination to avoid loading entire tables:
- `Paginator` for template views
- Cursor-based pagination for API endpoints (avoids COUNT query on large tables)

### Defer/Only
For views loading models but only using a few fields, check if `.defer()` or `.only()` could reduce data transfer.

## 5 — Query Budget Per View

For critical views, estimate query count:

| View | Expected Max Queries | Red Flag |
|------|---------------------|----------|
| Homepage | 5-10 | >15 |
| Firmware list | 3-5 | >10 |
| Firmware detail | 3-7 | >12 |
| Forum index | 5-8 | >15 |
| Topic detail | 4-8 | >12 |
| Admin dashboard | 10-20 | >30 |
| API list endpoints | 2-4 | >8 |

Use `assertNumQueries` pattern in tests to enforce query budgets.

## 6 — Static File Optimization

### WhiteNoise
Verify static file serving uses WhiteNoise in production:
- `whitenoise.middleware.WhiteNoiseMiddleware` in MIDDLEWARE
- `STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"` or equivalent

### Compression
Check that CSS and JS files have minified versions in `static/css/dist/` and `static/js/dist/`.

### Image Optimization
Check `static/img/` for:
- Images over 500KB that could be compressed
- Missing WebP alternatives for large images
- SVG brand logos are used where possible (vector > raster)

### Font Loading
Verify fonts use `font-display: swap` to prevent FOIT (Flash of Invisible Text). Check WOFF2 format is used (smallest).

## 7 — CDN Configuration

### Cache Headers
Verify static files have proper `Cache-Control` headers for browser caching:
- Hashed filenames (via ManifestStaticFilesStorage) → `max-age=31536000` (1 year)
- Non-hashed files → appropriate `max-age` with `must-revalidate`

### CDN Fallback
Verify multi-CDN fallback chain loads efficiently — check that fallback detection doesn't add excessive latency on primary CDN success.

## 8 — Lazy Loading

### Images
Verify `<img>` tags below the fold use `loading="lazy"` attribute.

### HTMX Deferred Loading
Check if heavy page sections use `hx-trigger="revealed"` for lazy loading when scrolled into view.

### Alpine x-intersect
Verify `x-intersect` is used for scroll-triggered data loading instead of loading everything upfront.

## 9 — Database Connection Pooling

Check `app/settings*.py` for connection pooling configuration:
- `CONN_MAX_AGE` setting (should not be 0 in production)
- Connection pool size appropriate for expected concurrency
- Separate connection settings for read replicas if configured

## 10 — Celery Task Performance

Check for:
- Long-running tasks that block workers
- Tasks that could be batched (many small tasks → one batch task)
- Tasks without proper timeouts (`time_limit`, `soft_time_limit`)
- Retry storms from misconfigured retry logic

## Report

```
[CRITICAL/HIGH/MEDIUM/LOW] Category — Finding
  File: apps/path/file.py:LINE
  Impact: Response time / query count / memory usage
  Fix: Specific optimization
  Expected Improvement: Estimated impact
```
