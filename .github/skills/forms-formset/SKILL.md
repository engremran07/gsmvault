---
name: forms-formset
description: "Formset and inline formset patterns with factory functions. Use when: editing multiple instances at once, parent-child inline editing, dynamic form rows."
---

# Formsets and Inline Formsets

## When to Use
- Editing a list of items at once (bulk edit)
- Parent-child inline editing (e.g., firmware + multiple files)
- Adding/removing dynamic form rows with JavaScript
- Admin-style inline model editing in custom views

## Rules
- Use `modelformset_factory` for standalone multi-item editing
- Use `inlineformset_factory` for parent-child relationships
- Always pass `queryset` to limit which instances are editable
- Set `extra=1` to show one empty form for new entries
- Set `can_delete=True` to allow row deletion

## Patterns

### Basic ModelFormSet
```python
from django.forms import modelformset_factory

FirmwareFormSet = modelformset_factory(
    Firmware,
    fields=["name", "version", "is_active"],
    extra=1,
    can_delete=True,
)

@login_required
@require_http_methods(["GET", "POST"])
def bulk_edit_firmwares(request: HttpRequest) -> HttpResponse:
    queryset = Firmware.objects.filter(is_active=True).select_related("brand")

    if request.method == "POST":
        formset = FirmwareFormSet(request.POST, queryset=queryset)
        if formset.is_valid():
            formset.save()
            messages.success(request, "Firmwares updated.")
            return redirect("firmwares:list")
    else:
        formset = FirmwareFormSet(queryset=queryset)

    return render(request, "firmwares/bulk_edit.html", {"formset": formset})
```

### Inline Formset (Parent-Child)
```python
from django.forms import inlineformset_factory

PollChoiceFormSet = inlineformset_factory(
    ForumPoll,           # Parent model
    ForumPollChoice,     # Child model
    fields=["text"],
    extra=3,             # 3 empty forms for new choices
    min_num=2,           # Minimum 2 choices required
    validate_min=True,
    can_delete=True,
    widgets={
        "text": forms.TextInput(attrs={"class": "form-input", "placeholder": "Choice text"}),
    },
)

@login_required
@require_http_methods(["GET", "POST"])
def edit_poll(request: HttpRequest, poll_pk: int) -> HttpResponse:
    poll = get_object_or_404(ForumPoll, pk=poll_pk)

    if request.method == "POST":
        formset = PollChoiceFormSet(request.POST, instance=poll)
        if formset.is_valid():
            formset.save()
            messages.success(request, "Poll choices updated.")
            return redirect("forum:topic_detail", pk=poll.topic.pk, slug=poll.topic.slug)
    else:
        formset = PollChoiceFormSet(instance=poll)

    return render(request, "forum/edit_poll.html", {"formset": formset, "poll": poll})
```

### Template Rendering
```html
<form method="post">
    {% csrf_token %}
    {{ formset.management_form }}

    <table class="admin-table">
        <thead>
            <tr>
                <th>Name</th>
                <th>Version</th>
                <th>Active</th>
                <th>Delete</th>
            </tr>
        </thead>
        <tbody>
            {% for form in formset %}
            <tr>
                {{ form.id }}  {# Hidden PK field #}
                <td>{{ form.name }}</td>
                <td>{{ form.version }}</td>
                <td>{{ form.is_active }}</td>
                <td>{{ form.DELETE }}</td>
            </tr>
            {% endfor %}
        </tbody>
    </table>

    <button type="submit" class="btn btn-primary">Save All</button>
</form>
```

### Dynamic Rows with Alpine.js
```html
<div x-data="{ formCount: {{ formset.total_form_count }} }">
    {{ formset.management_form }}

    <template x-for="i in formCount" :key="i">
        <div class="form-row">
            <!-- Form fields rendered dynamically -->
        </div>
    </template>

    <button type="button" @click="formCount++"
            class="btn btn-secondary">
        + Add Row
    </button>
</div>
```

### Custom Formset Validation
```python
from django.forms import BaseInlineFormSet

class PollChoiceFormSet(BaseInlineFormSet):
    def clean(self) -> None:
        super().clean()
        valid_choices = [
            form for form in self.forms
            if form.cleaned_data and not form.cleaned_data.get("DELETE")
        ]
        if len(valid_choices) < 2:
            raise forms.ValidationError("A poll must have at least 2 choices.")

PollChoiceFormSetFactory = inlineformset_factory(
    ForumPoll, ForumPollChoice,
    formset=PollChoiceFormSet,
    fields=["text"],
    extra=3,
)
```

## Anti-Patterns
- Forgetting `{{ formset.management_form }}` — formset won't process
- Missing `form.id` (hidden PK field) — existing instances won't update
- Not passing `queryset` — formset loads ALL instances
- Not passing `instance` for inline formsets — parent relation is missing
- Omitting `can_delete` when deletion should be allowed

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Formsets](https://docs.djangoproject.com/en/5.2/topics/forms/formsets/)
- [Django Inline Formsets](https://docs.djangoproject.com/en/5.2/topics/forms/modelforms/#inline-formsets)
