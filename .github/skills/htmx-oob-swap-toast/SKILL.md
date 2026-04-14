---
name: htmx-oob-swap-toast
description: "OOB swap for toast notifications. Use when: showing success/error toasts after HTMX actions, adding notifications alongside primary content updates."
---

# HTMX Out-of-Band Toast Notifications

## When to Use

- Showing a success toast after a form submission via HTMX
- Displaying error messages alongside content updates
- Triggering `$store.notify.show()` from server responses

## Rules

1. Use `HX-Trigger` response header to fire Alpine events — preferred approach
2. Alternatively use OOB swap to inject toast HTML into a container
3. Use the platform's `$store.notify` — never use `alert()` or inline HTML toasts
4. `HX-Trigger` approach is simpler and doesn't require DOM elements

## Patterns

### HX-Trigger Approach (Preferred)

```python
# views.py — trigger toast via response header
import json
from django.http import HttpResponse

def approve_firmware(request, pk):
    firmware = get_object_or_404(Firmware, pk=pk)
    firmware.status = "approved"
    firmware.save()

    response = render(request, "admin/fragments/firmware_row.html",
                      {"firmware": firmware})
    response["HX-Trigger"] = json.dumps({
        "showToast": {"message": f"{firmware.name} approved", "type": "success"}
    })
    return response
```

```html
{# templates/base/base.html — listen for showToast event #}
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('showToast', function(event) {
  const { message, type } = event.detail;
  Alpine.store('notify').show(message, type || 'info', 5000);
});
</script>
```

### OOB Swap Approach (Alternative)

```html
{# Response fragment — primary content + OOB toast #}
<tr id="fw-row-{{ firmware.pk }}">
  <td>{{ firmware.name }}</td>
  <td><span class="badge badge-success">Approved</span></td>
</tr>

{# OOB — inject script to trigger toast #}
<div id="toast-trigger" hx-swap-oob="true">
  <script nonce="{{ request.csp_nonce }}">
    Alpine.store('notify').show('{{ firmware.name }} approved', 'success');
  </script>
</div>
```

### Multiple Toasts After Bulk Action

```python
def bulk_approve(request):
    ids = request.POST.getlist("ids")
    count = Firmware.objects.filter(pk__in=ids).update(status="approved")

    response = render(request, "admin/fragments/firmware_table.html", context)
    response["HX-Trigger"] = json.dumps({
        "showToast": {"message": f"{count} firmware approved", "type": "success"}
    })
    return response
```

## Anti-Patterns

```python
# WRONG — using alert() for success message
# response["HX-Trigger"] = "alert('Success!')"

# WRONG — returning JSON toast data (HTMX expects HTML)
# return JsonResponse({"toast": "Success"})
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No feedback after HTMX action | User unsure if action worked | Add `HX-Trigger` with toast |
| `alert()` in response | Blocks UI | Use `$store.notify.show()` via event |
| Toast HTML hardcoded in fragments | Inconsistent, duplicated | Use `HX-Trigger` + event listener |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
