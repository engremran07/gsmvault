---
name: views-filtering
description: "Query filtering from GET params, django-filter integration. Use when: filtering list views by query params, building filter forms, faceted navigation."
---

# View Filtering

## When to Use
- List views with filter dropdowns (brand, category, status)
- URL query parameter filtering (`?brand=samsung&type=official`)
- Combined filtering + search + pagination
- Admin list views with sidebar filters

## Rules
- Validate/sanitize all GET params before using in queries
- Never pass raw GET params directly to `.filter()` kwargs — whitelist allowed fields
- Combine filtering with pagination — filter first, then paginate
- For complex filtering, use django-filter or a dedicated service function
- Default to showing all items when no filter is applied

## Patterns

### Manual GET Param Filtering
```python
@require_GET
def firmware_list(request: HttpRequest) -> HttpResponse:
    qs = Firmware.objects.filter(is_active=True).select_related("brand")

    # Safe filtering from GET params
    brand = request.GET.get("brand", "").strip()
    firmware_type = request.GET.get("type", "").strip()
    sort = request.GET.get("sort", "-created_at")

    if brand:
        qs = qs.filter(brand__slug=brand)
    if firmware_type:
        qs = qs.filter(firmware_type=firmware_type)

    # Whitelist allowed sort fields
    allowed_sorts = {"-created_at", "created_at", "name", "-name", "-download_count"}
    if sort not in allowed_sorts:
        sort = "-created_at"
    qs = qs.order_by(sort)

    paginator = Paginator(qs, 20)
    page_obj = paginator.get_page(request.GET.get("page"))

    context = {
        "page_obj": page_obj,
        "brands": Brand.objects.all(),
        "current_brand": brand,
        "current_type": firmware_type,
        "current_sort": sort,
    }

    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/list.html", context)
    return render(request, "firmwares/list.html", context)
```

### Filter Service Function
```python
# apps/firmwares/services.py
from django.db.models import QuerySet

def filter_firmwares(
    *,
    brand_slug: str = "",
    firmware_type: str = "",
    search_query: str = "",
    sort: str = "-created_at",
) -> QuerySet[Firmware]:
    qs = Firmware.objects.filter(is_active=True).select_related("brand")

    if brand_slug:
        qs = qs.filter(brand__slug=brand_slug)
    if firmware_type:
        qs = qs.filter(firmware_type=firmware_type)
    if search_query:
        qs = qs.filter(name__icontains=search_query)

    allowed_sorts = {"-created_at", "name", "-download_count"}
    return qs.order_by(sort if sort in allowed_sorts else "-created_at")

# In view:
@require_GET
def firmware_list(request: HttpRequest) -> HttpResponse:
    firmwares = filter_firmwares(
        brand_slug=request.GET.get("brand", ""),
        firmware_type=request.GET.get("type", ""),
        search_query=request.GET.get("q", ""),
        sort=request.GET.get("sort", "-created_at"),
    )
    ...
```

### HTMX Filter Form
```html
<!-- Filter form that triggers HTMX update -->
<form hx-get="{% url 'firmwares:list' %}"
      hx-target="#firmware-list"
      hx-swap="innerHTML"
      hx-trigger="change"
      hx-push-url="true">
    <select name="brand">
        <option value="">All Brands</option>
        {% for brand in brands %}
        <option value="{{ brand.slug }}" {% if brand.slug == current_brand %}selected{% endif %}>
            {{ brand.name }}
        </option>
        {% endfor %}
    </select>

    <select name="type">
        <option value="">All Types</option>
        <option value="official" {% if current_type == "official" %}selected{% endif %}>Official</option>
        <option value="modified" {% if current_type == "modified" %}selected{% endif %}>Modified</option>
    </select>
</form>

<div id="firmware-list">
    {% include "firmwares/fragments/list.html" %}
</div>
```

### Preserving Filters in Pagination
```html
<!-- In pagination component, preserve filter params -->
{% if page_obj.has_next %}
<a hx-get="?page={{ page_obj.next_page_number }}&brand={{ current_brand }}&type={{ current_type }}"
   hx-target="#firmware-list"
   hx-swap="innerHTML">
   Next
</a>
{% endif %}
```

## Anti-Patterns
- Passing raw GET params to `**kwargs` in `.filter()` — SQL injection risk
- Not whitelisting sort fields — user could sort by sensitive fields
- Filtering after pagination — apply filters before `Paginator`
- Losing filter state on page change — preserve params in pagination links
- Complex filter logic in views — extract to service function

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django QuerySet Filtering](https://docs.djangoproject.com/en/5.2/topics/db/queries/#retrieving-specific-objects-with-filters)
