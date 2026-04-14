---
name: htmx-django-messages-integration
description: "Django messages framework with HTMX. Use when: displaying Django messages after HTMX requests, showing success/error messages, toast notifications from server messages."
---

# HTMX Django Messages Integration

## When to Use

- Displaying `django.contrib.messages` after HTMX form submissions
- Showing success/warning/error messages without full page reload
- Integrating server-side messages with the `$store.notify` toast system

## Rules

1. HTMX fragments don't render base template → messages won't auto-display
2. Use OOB swap or `HX-Trigger` header to deliver messages to the toast system
3. Drain the messages iterator in the response to prevent stale messages
4. Prefer `HX-Trigger` with `showToast` event — cleanest approach

## Patterns

### HX-Trigger Approach (Preferred)

```python
import json
from django.contrib import messages

def create_firmware(request):
    form = FirmwareForm(request.POST, request.FILES)
    if form.is_valid():
        form.save()
        messages.success(request, "Firmware uploaded successfully")

        # Drain messages and convert to HX-Trigger
        msg_list = []
        for msg in messages.get_messages(request):
            msg_list.append({"message": str(msg), "type": msg.tags})

        response = render(request, "firmwares/fragments/success.html")
        if msg_list:
            response["HX-Trigger"] = json.dumps({
                "showToast": msg_list[0]  # Send first message as toast
            })
        return response

    return render(request, "firmwares/fragments/form.html",
                  {"form": form}, status=422)
```

### OOB Messages Container

```html
{# Include in every fragment that may have messages #}
{# templates/components/_htmx_messages.html #}

{% if messages %}
<div id="messages-container" hx-swap-oob="innerHTML">
  <script nonce="{{ request.csp_nonce }}">
    {% for message in messages %}
    Alpine.store('notify').show(
      '{{ message|escapejs }}',
      '{{ message.tags|default:"info" }}',
      5000
    );
    {% endfor %}
  </script>
</div>
{% endif %}
```

```html
{# Include in fragments #}
{# templates/firmwares/fragments/form_success.html #}

<div>
  <p>Firmware created successfully!</p>
</div>

{% include "components/_htmx_messages.html" %}
```

### Middleware for Automatic Message Headers

```python
# app/middleware/htmx_messages.py
import json
from django.contrib.messages import get_messages

class HtmxMessagesMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)

        if request.headers.get("HX-Request"):
            msg_list = [
                {"message": str(m), "type": m.tags}
                for m in get_messages(request)
            ]
            if msg_list:
                existing = response.get("HX-Trigger", "")
                triggers = json.loads(existing) if existing else {}
                triggers["showToast"] = msg_list[0]
                response["HX-Trigger"] = json.dumps(triggers)

        return response
```

## Anti-Patterns

```python
# WRONG — messages added but never drained (accumulate across requests)
messages.success(request, "Done!")
return render(request, "fragment.html")  # messages not read in fragment

# WRONG — rendering messages in fragment template with {% extends %}
# Fragments must NOT use extends
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| Messages accumulate across requests | Stale messages shown later | Drain messages in view |
| Messages in fragment with `{% extends %}` | Fragment breaks layout | Use OOB or HX-Trigger |
| No message display after HTMX POST | User gets no feedback | Add HX-Trigger header |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
