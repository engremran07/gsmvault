---
name: htmx-batch-operations-select
description: "Batch select/deselect for bulk operations. Use when: select-all checkbox in admin tables, bulk approve/reject, multi-item delete, batch status change."
---

# HTMX Batch Operations — Select/Deselect

## When to Use

- Admin tables with select-all and per-row checkbox
- Bulk approve/reject firmware or comments
- Selecting multiple items for batch delete or status change
- Any multi-item operation in a list/table view

## Rules

1. Use Alpine.js for client-side selection state management
2. Send selected IDs via HTMX POST as `ids[]` form values
3. Server validates ownership/permissions for ALL selected items
4. Show item count in the bulk action bar
5. Use `{% include "components/_admin_bulk_actions.html" %}` if available

## Patterns

### Select-All with Alpine.js + HTMX

```html
<div x-data="{ selectedIds: [], allSelected: false }">
  {# Bulk action bar — appears when items selected #}
  <div x-show="selectedIds.length > 0" x-cloak
       class="p-3 bg-[var(--color-bg-tertiary)] rounded mb-4 flex items-center gap-4">
    <span x-text="selectedIds.length + ' selected'"></span>
    <button hx-post="{% url 'admin:bulk_approve' %}"
            hx-target="#firmware-table"
            hx-include="[name='ids']"
            class="btn btn-sm btn-success">
      <i data-lucide="check-circle" class="w-4 h-4"></i> Approve
    </button>
    <button hx-post="{% url 'admin:bulk_reject' %}"
            hx-target="#firmware-table"
            hx-confirm="Reject selected items?"
            hx-include="[name='ids']"
            class="btn btn-sm btn-danger">
      <i data-lucide="x-circle" class="w-4 h-4"></i> Reject
    </button>
  </div>

  {# Hidden inputs to carry IDs in HTMX request #}
  <template x-for="id in selectedIds" :key="id">
    <input type="hidden" name="ids" :value="id">
  </template>

  <table id="firmware-table">
    <thead>
      <tr>
        <th>
          <input type="checkbox"
                 @change="allSelected = $event.target.checked;
                          selectedIds = allSelected
                            ? [...document.querySelectorAll('[data-item-id]')].map(el => el.dataset.itemId)
                            : []">
        </th>
        <th>Name</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
      {% for fw in firmwares %}
      <tr data-item-id="{{ fw.pk }}">
        <td>
          <input type="checkbox"
                 :checked="selectedIds.includes('{{ fw.pk }}')"
                 @change="$event.target.checked
                   ? selectedIds.push('{{ fw.pk }}')
                   : selectedIds = selectedIds.filter(id => id !== '{{ fw.pk }}')">
        </td>
        <td>{{ fw.name }}</td>
        <td>{{ fw.status }}</td>
      </tr>
      {% endfor %}
    </tbody>
  </table>
</div>
```

### Django Bulk Action View

```python
@login_required
@require_POST
def bulk_approve(request):
    if not getattr(request.user, "is_staff", False):
        return HttpResponse(status=403)

    ids = request.POST.getlist("ids")
    updated = Firmware.objects.filter(pk__in=ids, status="pending").update(
        status="approved"
    )

    response = render(request, "admin/fragments/firmware_table.html",
                      {"firmwares": Firmware.objects.all()})
    response["HX-Trigger"] = json.dumps({
        "showToast": {"message": f"{updated} firmware approved", "type": "success"}
    })
    return response
```

## Anti-Patterns

```html
<!-- WRONG — no staff check in bulk action -->
<!-- WRONG — selecting by DOM manipulation instead of Alpine state -->
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No permission check in bulk view | Non-staff can bulk modify | Check `is_staff` |
| No count display | User unsure how many selected | Show `selectedIds.length` |
| `hx-include` targeting wrong inputs | Wrong IDs sent to server | Use `[name='ids']` selector |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
