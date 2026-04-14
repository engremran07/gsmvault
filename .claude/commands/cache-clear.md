# /cache-clear â€” Clear all application caches

Flush Django cache framework, Redis keys, template cache, and static file cache.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Clear Django Cache Framework

- [ ] Clear default cache:

  ```powershell
  & .\.venv\Scripts\python.exe manage.py shell --settings=app.settings_dev -c "from django.core.cache import cache; cache.clear(); print('Django cache cleared')"
  ```

- [ ] If multiple cache backends configured, clear each one

### Step 2: Clear Redis Cache

- [ ] Flush Redis DB: `redis-cli FLUSHDB` (current database only)

- [ ] Verify flush: `redis-cli DBSIZE` (should return 0)

- [ ] WARNING: This clears Celery broker data too â€” confirm no critical tasks in queue first

### Step 3: Clear Template Cache

- [ ] Django template cache is in-memory per process â€” restart dev server to clear

- [ ] If using cached template loader, it resets on server restart

### Step 4: Clear Static File Cache

- [ ] Delete collected static: `Remove-Item -Recurse -Force staticfiles\` (if exists, confirm first)

- [ ] Re-collect: `& .\.venv\Scripts\python.exe manage.py collectstatic --noinput --settings=app.settings_dev`

- [ ] Clear browser cache or hard-refresh (Ctrl+Shift+R) to verify

### Step 5: Clear DistributedCacheManager State

- [ ] If `apps.core.cache.DistributedCacheManager` has namespace keys, clear those:

  ```powershell
  & .\.venv\Scripts\python.exe manage.py shell --settings=app.settings_dev -c "from apps.core.cache import DistributedCacheManager; print('Check DistributedCacheManager state')"
  ```

### Step 6: Verify

- [ ] Restart dev server: `& .\.venv\Scripts\python.exe manage.py runserver --settings=app.settings_dev`

- [ ] Confirm pages load correctly without cached data

- [ ] Check that cache-dependent features rebuild properly (SEO metadata, ad placements, etc.)
