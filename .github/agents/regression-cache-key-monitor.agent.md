---
name: regression-cache-key-monitor
description: >-
  Monitors cache key namespacing and invalidation.
  Use when: cache audit, key collision check, invalidation pattern scan.
---

# Regression Cache Key Monitor

Detects cache key regressions: missing namespacing, stale cache after model updates, key collisions across apps.

## Rules

1. All cache keys must be namespaced with the app name to prevent cross-app collisions — missing is HIGH.
2. Use `DistributedCacheManager` from `apps.core.cache` for all caching operations.
3. Cache invalidation must occur on model save/delete — stale cache is HIGH.
4. Verify cache keys do not include user-controlled input without sanitization.
5. Check that cache timeout values are reasonable — infinite cache without invalidation is HIGH.
6. Flag any direct `cache.set()` / `cache.get()` without using `DistributedCacheManager`.
7. Verify cache backend configuration in settings is not weakened.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
