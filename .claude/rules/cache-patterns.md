---
paths: ["apps/*/services*.py", "apps/*/views.py"]
---

# Cache Patterns

Rules for caching across the platform. Redis is the cache backend.

## Cache Infrastructure

- Use `apps.core.cache.DistributedCacheManager` for complex, multi-key, or cross-app caching.
- Use Django's `cache` framework (`django.core.cache.cache`) for simple key-value lookups.
- NEVER instantiate direct Redis clients — always go through the cache abstraction layer.
- Import cache utilities from `apps.core.cache` — never from `django_redis` directly.

## Key Naming & TTL

- Cache keys MUST be namespaced by app: `{app}:{model}:{pk}` (e.g., `firmwares:firmware:42`).
- ALWAYS set a TTL on cached values — never cache indefinitely (`timeout=None` is FORBIDDEN).
- Use short TTLs (60–300s) for rapidly changing data (online users, stats).
- Use longer TTLs (3600–86400s) for stable data (site settings, device catalogs).
- Include version or hash in cache keys when cached structure changes between deploys.

## Invalidation

- Invalidate on write: clear related cache keys in the service layer after model mutations.
- Use `cache.delete_pattern()` for bulk invalidation of namespaced keys.
- NEVER rely on TTL expiry alone for data that users expect to update immediately.
- Signal-driven invalidation: connect to `post_save`/`post_delete` for model-level cache busting.

## User-Specific Caching

- NEVER cache user-specific data in a shared cache key — always include `user:{user_id}` in the key.
- Session data belongs in the session backend, not in the cache layer.
- Authenticated API responses: cache per-user or mark as `Cache-Control: private`.
- Anonymous page caching is safe only for truly public, non-personalized content.

## Template Fragment Caching

- Use `{% cache TTL key %}` for expensive template renders (KPI cards, sidebar stats).
- Fragment cache keys MUST include variables that change the rendered output.
- NEVER cache fragments that contain CSRF tokens or user-specific content without a user key.
- Prefer server-side caching over client-side `Cache-Control` for dynamic pages.

## Cache Warming

- Warm caches on deploy or via periodic Celery task — never on first user request.
- Pre-populate frequently accessed querysets (popular devices, featured firmware).
- Monitor cache hit/miss ratio — low hit rates indicate bad key design or premature eviction.
