---
name: views-class-based
description: "Class-based views: ListView, DetailView, CreateView, UpdateView, DeleteView. Use when: CRUD views, generic views, complex view logic with multiple methods."
---

# Class-Based Views

## When to Use
- Standard CRUD operations (list, detail, create, update, delete)
- Views with complex method dispatch (GET, POST, PUT, DELETE)
- Views that benefit from mixin composition
- Reusable view patterns across apps

## Rules
- Prefer function-based views for simple endpoints — CBVs for CRUD patterns
- Always set `model`, `template_name`, and `context_object_name`
- Override `get_queryset()` for filtering — annotate return type
- Business logic in `services.py` — `form_valid()` delegates, doesn't compute
- Views CAN import from multiple apps — they are orchestrators

## Patterns

### ListView with Filtering
```python
from django.views.generic import ListView
from django.db.models import QuerySet

from .models import Firmware

class FirmwareListView(ListView):
    model = Firmware
    template_name = "firmwares/list.html"
    context_object_name = "firmwares"
    paginate_by = 20

    def get_queryset(self) -> QuerySet[Firmware]:
        qs = Firmware.objects.filter(is_active=True).select_related("brand")
        brand = self.request.GET.get("brand")
        if brand:
            qs = qs.filter(brand__slug=brand)
        return qs

    def get_template_names(self) -> list[str]:
        if self.request.headers.get("HX-Request"):
            return ["firmwares/fragments/list.html"]
        return [self.template_name]
```

### DetailView
```python
from django.views.generic import DetailView

class FirmwareDetailView(DetailView):
    model = Firmware
    template_name = "firmwares/detail.html"
    context_object_name = "firmware"

    def get_queryset(self) -> QuerySet[Firmware]:
        return Firmware.objects.select_related("brand").prefetch_related("tags")

    def get_context_data(self, **kwargs: Any) -> dict[str, Any]:
        context = super().get_context_data(**kwargs)
        context["related"] = Firmware.objects.filter(
            brand=self.object.brand
        ).exclude(pk=self.object.pk)[:5]
        return context
```

### CreateView with Service Delegation
```python
from django.views.generic import CreateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy

class TopicCreateView(LoginRequiredMixin, CreateView):
    model = ForumTopic
    form_class = TopicForm
    template_name = "forum/create_topic.html"

    def form_valid(self, form: TopicForm) -> HttpResponse:
        # Delegate to service layer — don't put logic here
        topic = create_new_topic(
            author=self.request.user,
            **form.cleaned_data,
        )
        return redirect("forum:topic_detail", pk=topic.pk, slug=topic.slug)
```

### UpdateView with Ownership Check
```python
from django.views.generic import UpdateView
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin

class TopicUpdateView(LoginRequiredMixin, UserPassesTestMixin, UpdateView):
    model = ForumTopic
    form_class = TopicForm
    template_name = "forum/edit_topic.html"

    def test_func(self) -> bool:
        topic = self.get_object()
        return topic.author == self.request.user or getattr(self.request.user, "is_staff", False)

    def get_success_url(self) -> str:
        return reverse("forum:topic_detail", kwargs={"pk": self.object.pk, "slug": self.object.slug})
```

### DeleteView with Confirmation
```python
from django.views.generic import DeleteView

class TopicDeleteView(LoginRequiredMixin, UserPassesTestMixin, DeleteView):
    model = ForumTopic
    template_name = "forum/confirm_delete.html"
    success_url = reverse_lazy("forum:index")

    def test_func(self) -> bool:
        return getattr(self.request.user, "is_staff", False)
```

### URL Configuration
```python
# apps/firmwares/urls.py
from django.urls import path
from . import views

app_name = "firmwares"

urlpatterns = [
    path("", views.FirmwareListView.as_view(), name="list"),
    path("<int:pk>/", views.FirmwareDetailView.as_view(), name="detail"),
    path("create/", views.TopicCreateView.as_view(), name="create"),
]
```

## Anti-Patterns
- Overriding `dispatch()` for simple auth — use `LoginRequiredMixin`
- Business logic in `form_valid()` — delegate to `services.py`
- Not annotating `get_queryset()` return type — Pyright flags this
- Missing `select_related` in `get_queryset()` — causes N+1
- Using `model = MyModel` without `context_object_name` — template gets `object` not a descriptive name

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Class-Based Views](https://docs.djangoproject.com/en/5.2/topics/class-based-views/)
- [Django CBV Reference](https://ccbv.co.uk/)
