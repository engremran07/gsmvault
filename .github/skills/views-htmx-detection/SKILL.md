---
name: views-htmx-detection
description: "HTMX request detection pattern: request.headers.get('HX-Request'). Use when: serving both full pages and HTMX fragments, partial page updates, HTMX response headers."
---

# HTMX Detection in Views

## When to Use
- A single view that serves a full page OR an HTMX fragment
- Setting HTMX response headers (retarget, reswap, trigger events)
- Handling HTMX-specific form submissions
- Returning different content/status for HTMX vs full-page requests

## Rules
- Detect with `request.headers.get("HX-Request")` — returns `"true"` or `None`
- HTMX fragments MUST NOT use `{% extends %}` — they are standalone snippets
- Full-page responses use `{% extends "layouts/default.html" %}`
- CSRF is handled globally by `<body hx-headers='{"X-CSRFToken": "..."}'>` — no per-view CSRF setup
- Never return JSON from HTMX views — return HTML fragments

## Patterns

### Basic HTMX Detection
```python
@require_GET
def firmware_list(request: HttpRequest) -> HttpResponse:
    firmwares = Firmware.objects.filter(is_active=True).select_related("brand")
    paginator = Paginator(firmwares, 20)
    page_obj = paginator.get_page(request.GET.get("page"))
    context = {"page_obj": page_obj}

    if request.headers.get("HX-Request"):
        return render(request, "firmwares/fragments/list.html", context)
    return render(request, "firmwares/list.html", context)
```

### HTMX Form Submission
```python
@require_http_methods(["GET", "POST"])
@login_required
def create_reply(request: HttpRequest, topic_pk: int) -> HttpResponse:
    topic = get_object_or_404(ForumTopic, pk=topic_pk)

    if request.method == "POST":
        form = ReplyForm(request.POST)
        if form.is_valid():
            reply = create_new_reply(topic=topic, author=request.user, **form.cleaned_data)
            if request.headers.get("HX-Request"):
                return render(request, "forum/fragments/reply_item.html", {"reply": reply})
            return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)

        # Form errors — return form with errors for HTMX or full page
        if request.headers.get("HX-Request"):
            return render(request, "forum/fragments/reply_form.html", {"form": form}, status=422)

    form = ReplyForm()
    context = {"form": form, "topic": topic}
    if request.headers.get("HX-Request"):
        return render(request, "forum/fragments/reply_form.html", context)
    return render(request, "forum/create_reply.html", context)
```

### HTMX Response Headers
```python
from django.http import HttpResponse

def toggle_like(request: HttpRequest, reply_pk: int) -> HttpResponse:
    reply = get_object_or_404(ForumReply, pk=reply_pk)
    liked = toggle_reply_like(reply, request.user)

    response = render(request, "forum/fragments/like_button.html", {
        "reply": reply, "liked": liked,
    })
    # Trigger client-side event after swap
    response["HX-Trigger"] = "likeToggled"
    return response

def delete_topic(request: HttpRequest, pk: int) -> HttpResponse:
    delete_forum_topic(pk, deleted_by=request.user)
    response = HttpResponse(status=200)
    # Redirect the whole page after HTMX delete
    response["HX-Redirect"] = reverse("forum:index")
    return response
```

### HTMX Search with Debounce
```python
@require_GET
def search_firmwares(request: HttpRequest) -> HttpResponse:
    query = request.GET.get("q", "").strip()
    results = Firmware.objects.none()
    if len(query) >= 2:
        results = Firmware.objects.filter(
            name__icontains=query, is_active=True
        ).select_related("brand")[:10]

    return render(request, "firmwares/fragments/search_results.html", {
        "results": results,
        "query": query,
    })
```

### Template Side
```html
<!-- Full page template: firmwares/list.html -->
{% extends "layouts/default.html" %}
{% block content %}
<div id="firmware-list">
    {% include "firmwares/fragments/list.html" %}
</div>
{% endblock %}

<!-- Fragment: firmwares/fragments/list.html — NO extends! -->
{% for fw in page_obj %}
<div class="firmware-card">{{ fw.name }}</div>
{% endfor %}
{% include "components/_pagination.html" with page_obj=page_obj %}
```

## Anti-Patterns
- Returning JSON from HTMX views — HTMX expects HTML
- Using `{% extends %}` in HTMX fragments — fragments are injected into existing pages
- Checking `request.is_ajax()` — removed in Django 4.0, use `request.headers.get("HX-Request")`
- Per-view CSRF setup for HTMX — global `<body hx-headers>` already handles this
- Returning full page to HTMX request — wastes bandwidth, breaks partial updates

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [HTMX Request Headers](https://htmx.org/reference/#request_headers)
- [HTMX Response Headers](https://htmx.org/reference/#response_headers)
