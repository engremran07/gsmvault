---
name: alp-intersect-infinite
description: "Infinite scroll with x-intersect. Use when: loading more items on scroll, paginated API with append-on-scroll, forum topic lists, firmware catalog browsing."
---

# Alpine Infinite Scroll with x-intersect

## When to Use

- Topic/reply lists that load more as user scrolls down
- Firmware catalog with progressive loading
- Any paginated list where "load more" should be automatic

## Patterns

### Basic Infinite Scroll

```html
<div x-data="{
  items: [],
  page: 1,
  loading: false,
  hasMore: true,
  async loadMore() {
    if (this.loading || !this.hasMore) return;
    this.loading = true;
    try {
      const res = await fetch(`/api/v1/firmwares/?page=${this.page}`);
      const data = await res.json();
      this.items.push(...data.results);
      this.hasMore = !!data.next;
      this.page++;
    } finally {
      this.loading = false;
    }
  }
}" x-init="loadMore()">

  <template x-for="item in items" :key="item.id">
    <div class="p-4 border-b border-[var(--color-border)]">
      <h3 x-text="item.name"></h3>
    </div>
  </template>

  <!-- Sentinel element -->
  <div x-show="hasMore" x-intersect:enter="loadMore()" class="py-4">
    <div x-show="loading" class="flex justify-center">
      {% include "components/_loading.html" with size="sm" %}
    </div>
  </div>

  <p x-show="!hasMore && items.length > 0" x-cloak
     class="text-center text-[var(--color-text-muted)] py-4">
    No more items
  </p>
</div>
```

### With HTMX Hybrid (Server-Rendered Items)

```html
<div id="item-list">
  {% for item in items %}
    {% include "firmwares/fragments/_firmware_card.html" %}
  {% endfor %}
</div>

<div x-data="{ page: 1, hasMore: {{ has_next|yesno:'true,false' }} }"
     x-show="hasMore" x-cloak
     x-intersect:enter="
       page++;
       htmx.ajax('GET', '?page=' + page, { target: '#item-list', swap: 'beforeend' });
     ">
  {% include "components/_loading.html" with size="sm" %}
</div>
```

### Debounced Scroll Loading

```html
<div x-data="{
  canLoad: true,
  loadMore() {
    if (!this.canLoad) return;
    this.canLoad = false;
    // fetch logic...
    setTimeout(() => this.canLoad = true, 500);
  }
}" x-intersect:enter="loadMore()">
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| No guard against concurrent loads | Duplicate items | Check `loading` flag before fetch |
| Missing `hasMore` check | Fetches after last page returns empty | Track `next` from API response |
| Sentinel always visible | Infinite loop of requests | Hide sentinel when no more data |

## Red Flags

- Infinite scroll without loading indicator (user doesn't know content is coming)
- No "end of list" message when all items are loaded
- Missing deduplication — same items appended multiple times

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
