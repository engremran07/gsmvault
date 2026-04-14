---
name: htmx-infinite-scroll-button
description: "Load more button pattern. Use when: user-controlled pagination, 'Show more' buttons, manual load-more instead of auto-scroll."
---

# HTMX Load More Button

## When to Use

- User-controlled "Load More" instead of auto infinite scroll
- Mobile-friendly pagination where scroll detection is unreliable
- Lists where the user should consciously decide to load more
- Admin panels with large datasets

## Rules

1. Place a "Load More" button at the end of the list
2. Button fetches next page and replaces itself with new items + new button
3. Use `hx-swap="outerHTML"` so the button replaces itself
4. Hide the button when there are no more pages
5. Disable button during loading with `hx-disabled-elt`

## Patterns

### Load More Button

```html
{# templates/firmwares/fragments/firmware_cards.html #}
{% for fw in page_obj %}
<div class="card p-4 border rounded-lg">
  <h3>{{ fw.name }}</h3>
  <p class="text-sm text-[var(--color-text-muted)]">{{ fw.brand.name }}</p>
</div>
{% endfor %}

{% if page_obj.has_next %}
<div class="text-center py-4">
  <button hx-get="?page={{ page_obj.next_page_number }}"
          hx-target="this"
          hx-swap="outerHTML"
          hx-indicator="#load-more-spinner"
          hx-disabled-elt="this"
          class="px-6 py-2 rounded-lg bg-[var(--color-accent)] text-[var(--color-accent-text)]">
    <span>Load More</span>
    <span id="load-more-spinner" class="htmx-indicator ml-2">
      <i data-lucide="loader-2" class="w-4 h-4 animate-spin inline"></i>
    </span>
  </button>
</div>
{% else %}
<p class="text-center py-4 text-sm text-[var(--color-text-muted)]">
  No more firmware to load
</p>
{% endif %}
```

### With Item Count

```html
{% if page_obj.has_next %}
<div class="text-center py-4">
  <p class="text-sm text-[var(--color-text-muted)] mb-2">
    Showing {{ page_obj.start_index }}-{{ page_obj.end_index }}
    of {{ page_obj.paginator.count }}
  </p>
  <button hx-get="?page={{ page_obj.next_page_number }}"
          hx-target="this"
          hx-swap="outerHTML"
          hx-disabled-elt="this">
    Load More ({{ page_obj.paginator.count|add:"-"|add:page_obj.end_index }} remaining)
  </button>
</div>
{% endif %}
```

### Django View

```python
def firmware_list(request):
    firmwares = Firmware.objects.filter(is_active=True).select_related("brand")
    paginator = Paginator(firmwares, 12)
    page = paginator.get_page(request.GET.get("page", 1))
    context = {"page_obj": page}

    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/firmware_cards.html", context)
    return render(request, "firmwares/firmware_list.html", context)
```

## Anti-Patterns

```html
<!-- WRONG — button doesn't replace itself (button duplicates) -->
<button hx-get="?page=2" hx-target="#list" hx-swap="beforeend">Load More</button>

<!-- WRONG — no disabled state (user can click multiple times) -->
<button hx-get="?page=2" hx-target="this" hx-swap="outerHTML">Load More</button>
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| Button duplicates on click | Wrong swap target | Use `hx-target="this"` + `hx-swap="outerHTML"` |
| Multiple rapid clicks | Duplicate content | Add `hx-disabled-elt="this"` |
| Button on last page | Loads empty content | Only render if `has_next` |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
