---
name: htmx-oob-swap-delete
description: "OOB swap for deleting elements. Use when: removing a DOM element after a delete action, removing table rows, removing list items via HTMX."
---

# HTMX Out-of-Band Swap — Delete

## When to Use

- Removing a DOM element after a successful delete request
- Removing a table row after deleting a record
- Removing a card/item from a list
- Deleting with a confirmation and smooth removal

## Rules

1. Use `hx-swap="outerHTML"` with empty response to remove the element
2. Or use `hx-swap="delete"` to remove the target element
3. For animated removal, use CSS transitions before the swap
4. Always confirm destructive actions — use `hx-confirm` or Alpine modal

## Patterns

### Simple Delete with Row Removal

```html
{# Each row wraps the delete button #}
<tr id="fw-row-{{ fw.pk }}">
  <td>{{ fw.name }}</td>
  <td>{{ fw.brand.name }}</td>
  <td>
    <button hx-delete="{% url 'firmwares:delete' fw.pk %}"
            hx-target="#fw-row-{{ fw.pk }}"
            hx-swap="outerHTML swap:500ms"
            hx-confirm="Delete {{ fw.name }}? This cannot be undone."
            class="text-red-500 hover:text-red-700">
      <i data-lucide="trash-2" class="w-4 h-4"></i>
    </button>
  </td>
</tr>
```

### Django Delete View

```python
from django.http import HttpResponse

@login_required
def delete_firmware(request, pk):
    firmware = get_object_or_404(Firmware, pk=pk, uploaded_by=request.user)
    firmware.delete()
    return HttpResponse("")  # Empty response — element removed by outerHTML swap
```

### Delete with OOB Counter Update

```html
{# Response: empty primary target + OOB counter update #}
{# Primary target is empty — removes the row #}

{# OOB — update the total count #}
<span id="firmware-count" hx-swap-oob="true">{{ remaining_count }} firmware files</span>
```

### Animated Removal

```html
<div id="item-{{ item.pk }}" class="transition-all duration-300">
  <button hx-delete="{% url 'items:delete' item.pk %}"
          hx-target="#item-{{ item.pk }}"
          hx-swap="outerHTML swap:300ms settle:300ms"
          hx-confirm="Delete this item?">
    Delete
  </button>
</div>
```

```css
/* Fade out before removal */
.htmx-swapping { opacity: 0; transition: opacity 300ms ease-out; }
```

## Anti-Patterns

```html
<!-- WRONG — delete without confirmation -->
<button hx-delete="/api/firmware/5/">Delete</button>

<!-- WRONG — hiding instead of removing (element still in DOM) -->
<button hx-delete="/api/item/5/" hx-target="this" hx-swap="innerHTML">
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No `hx-confirm` on delete | User accidentally deletes | Add `hx-confirm` or Alpine modal |
| Element not removed from DOM | Stale data visible | Use `hx-swap="outerHTML"` with empty response |
| No ownership check in view | Any user can delete | Validate `uploaded_by=request.user` |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
