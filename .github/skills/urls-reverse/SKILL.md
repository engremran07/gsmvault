---
name: urls-reverse
description: "reverse() and reverse_lazy() usage, template {% url %} tag. Use when: generating URLs in views, templates, models, forms, or redirect targets."
---

# URL Reverse Resolution

## When to Use
- Generating URLs in views with `reverse()` or `redirect()`
- Building URLs in templates with `{% url %}`
- Setting `success_url` on class-based views with `reverse_lazy()`
- Constructing URLs in model methods or serializers

## Rules
- NEVER hardcode URLs — always use `reverse()`, `reverse_lazy()`, or `{% url %}`
- Use `reverse_lazy()` in class-level attributes (evaluated at import time)
- Use `reverse()` in functions/methods (evaluated at call time)
- Always include namespace prefix: `reverse("firmwares:detail", ...)`
- Pass arguments via `kwargs=` dict, not positional `args=`

## Patterns

### reverse() in Views
```python
from django.urls import reverse
from django.shortcuts import redirect

def approve_firmware(request: HttpRequest, pk: int) -> HttpResponse:
    # Process approval...
    url = reverse("firmwares:detail", kwargs={"pk": pk})
    return redirect(url)

# Shortcut — redirect() accepts namespace:name directly
def quick_redirect(request: HttpRequest) -> HttpResponse:
    return redirect("firmwares:list")
```

### reverse_lazy() in Class Attributes
```python
from django.urls import reverse_lazy
from django.views.generic import CreateView

class FirmwareCreateView(CreateView):
    model = Firmware
    form_class = FirmwareForm
    # MUST use reverse_lazy() — evaluated at class definition time
    success_url = reverse_lazy("firmwares:list")

    def get_success_url(self) -> str:
        # Inside methods, regular reverse() is fine
        return reverse("firmwares:detail", kwargs={"pk": self.object.pk})
```

### {% url %} in Templates
```html
<!-- Basic usage -->
<a href="{% url 'firmwares:list' %}">All Firmware</a>

<!-- With arguments -->
<a href="{% url 'firmwares:detail' pk=fw.pk %}">{{ fw.name }}</a>

<!-- Multiple arguments -->
<a href="{% url 'forum:topic_detail' pk=topic.pk slug=topic.slug %}">
    {{ topic.title }}
</a>

<!-- In forms -->
<form action="{% url 'firmwares:download' pk=fw.pk %}" method="post">
    {% csrf_token %}
    <button type="submit">Download</button>
</form>

<!-- Store in variable with 'as' -->
{% url 'firmwares:detail' pk=fw.pk as fw_url %}
<a href="{{ fw_url }}">{{ fw.name }}</a>
```

### reverse() in Serializers / Models
```python
# In DRF serializers
class FirmwareSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    def get_url(self, obj: Firmware) -> str:
        return reverse("firmwares:detail", kwargs={"pk": obj.pk})

# In model methods
class Firmware(TimestampedModel):
    def get_absolute_url(self) -> str:
        return reverse("firmwares:detail", kwargs={"pk": self.pk})
```

### Building URLs with Query Parameters
```python
from urllib.parse import urlencode

def search_redirect(request: HttpRequest) -> HttpResponse:
    base_url = reverse("firmwares:list")
    query = urlencode({"q": request.POST["search"], "page": 1})
    return redirect(f"{base_url}?{query}")
```

## Anti-Patterns
- NEVER use `reverse()` in class-level attributes — use `reverse_lazy()`
- NEVER hardcode: `"/firmwares/42/"` — use `reverse("firmwares:detail", kwargs={"pk": 42})`
- NEVER pass args positionally: `reverse("fw:detail", args=[42])` — use `kwargs={"pk": 42}`
- NEVER concatenate URL segments manually — rely on the URL router

## Red Flags
- `NoReverseMatch` — verify app_name, namespace, pattern name, and kwargs match
- `reverse()` in class body outside a method → needs `reverse_lazy()`
- Hardcoded `/api/v1/...` strings in Python code

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- `app/urls.py` — root URL config with all namespaces
- `.claude/rules/urls-layer.md` — URL layer conventions
