---
name: forms-widgets
description: "Custom widgets: DateInput, Select2, file upload widgets. Use when: customizing form field rendering, date/time pickers, rich selects, file upload UX."
---

# Custom Form Widgets

## When to Use
- Customizing how form fields render in HTML
- Adding date/time pickers with proper input types
- Rich select dropdowns with search (Select2-style via Alpine.js)
- Custom file upload widgets with preview
- Applying Tailwind CSS classes to form inputs

## Rules
- Set widget attributes in `Meta.widgets` or field constructor
- Use HTML5 input types (`datetime-local`, `date`, `email`, `url`) for native UX
- Custom widgets that need JavaScript should use Alpine.js — not jQuery
- Always include CSS classes matching the design system (`form-input`, `form-select`)
- For file uploads: validate MIME type and size in the form `clean_*` method

## Patterns

### HTML5 Input Type Widgets
```python
class CampaignForm(forms.ModelForm):
    class Meta:
        model = Campaign
        fields = ["name", "start_at", "end_at", "budget"]
        widgets = {
            "name": forms.TextInput(attrs={
                "class": "form-input",
                "placeholder": "Campaign name",
                "autofocus": True,
            }),
            "start_at": forms.DateTimeInput(attrs={
                "type": "datetime-local",
                "class": "form-input",
            }),
            "end_at": forms.DateTimeInput(attrs={
                "type": "datetime-local",
                "class": "form-input",
            }),
            "budget": forms.NumberInput(attrs={
                "class": "form-input",
                "step": "0.01",
                "min": "0",
            }),
        }
```

### Textarea with Character Count
```python
class TopicForm(forms.ModelForm):
    class Meta:
        model = ForumTopic
        fields = ["title", "content"]
        widgets = {
            "title": forms.TextInput(attrs={
                "class": "form-input",
                "maxlength": "300",
                "placeholder": "Topic title",
                "x-data": "",
                "x-on:input": "$el.nextElementSibling.textContent = $el.value.length + '/300'",
            }),
            "content": forms.Textarea(attrs={
                "class": "form-textarea",
                "rows": 8,
                "placeholder": "Write your post...",
            }),
        }
```

### Select with Empty Label
```python
class FirmwareFilterForm(forms.Form):
    brand = forms.ModelChoiceField(
        queryset=Brand.objects.all(),
        required=False,
        empty_label="All Brands",
        widget=forms.Select(attrs={"class": "form-select"}),
    )
    firmware_type = forms.ChoiceField(
        choices=[("", "All Types")] + list(FirmwareType.choices),
        required=False,
        widget=forms.Select(attrs={"class": "form-select"}),
    )
```

### Checkbox and Radio Widgets
```python
class SettingsForm(forms.Form):
    notifications = forms.BooleanField(
        required=False,
        widget=forms.CheckboxInput(attrs={"class": "form-checkbox"}),
    )
    theme = forms.ChoiceField(
        choices=[("dark", "Dark"), ("light", "Light"), ("contrast", "High Contrast")],
        widget=forms.RadioSelect(attrs={"class": "form-radio"}),
    )
```

### File Upload with Preview (Alpine.js)
```html
<!-- Template for file upload widget -->
<div x-data="{ fileName: '', preview: '' }" class="form-group">
    <label>{{ field.label }}</label>
    <input type="file"
           name="{{ field.html_name }}"
           accept=".zip,.rar,.7z,.bin"
           class="form-input"
           @change="fileName = $event.target.files[0]?.name || ''"
           x-cloak />
    <p x-show="fileName" x-text="'Selected: ' + fileName" class="text-sm text-muted" x-cloak></p>
</div>
```

### Image Upload with Preview
```html
<div x-data="{ preview: '' }" class="form-group">
    <label>Logo</label>
    <input type="file"
           name="logo"
           accept="image/*"
           class="form-input"
           @change="
               const file = $event.target.files[0];
               if (file) {
                   const reader = new FileReader();
                   reader.onload = (e) => preview = e.target.result;
                   reader.readAsDataURL(file);
               }
           " />
    <img x-show="preview" :src="preview" class="mt-2 h-20 w-20 object-cover rounded" x-cloak />
</div>
```

### Custom Widget Class
```python
class TailwindTextInput(forms.TextInput):
    """TextInput pre-configured with Tailwind CSS classes."""
    def __init__(self, attrs: dict[str, Any] | None = None) -> None:
        default_attrs = {"class": "form-input"}
        if attrs:
            default_attrs.update(attrs)
        super().__init__(attrs=default_attrs)

class TailwindSelect(forms.Select):
    """Select pre-configured with Tailwind CSS classes."""
    def __init__(self, attrs: dict[str, Any] | None = None, choices: Any = ()) -> None:
        default_attrs = {"class": "form-select"}
        if attrs:
            default_attrs.update(attrs)
        super().__init__(attrs=default_attrs, choices=choices)

# Usage:
class MyForm(forms.ModelForm):
    class Meta:
        model = MyModel
        fields = ["name", "category"]
        widgets = {
            "name": TailwindTextInput(attrs={"placeholder": "Enter name"}),
            "category": TailwindSelect(),
        }
```

### Widget Reference Table

| Purpose | Widget | HTML5 Type |
|---|---|---|
| Short text | `TextInput` | `text` |
| Long text | `Textarea` | — |
| Email | `EmailInput` | `email` |
| URL | `URLInput` | `url` |
| Number | `NumberInput` | `number` |
| Date | `DateInput` | `date` |
| DateTime | `DateTimeInput` | `datetime-local` |
| Time | `TimeInput` | `time` |
| Password | `PasswordInput` | `password` |
| File | `FileInput` | `file` |
| Checkbox | `CheckboxInput` | `checkbox` |
| Select | `Select` | — |
| Multi-select | `SelectMultiple` | — |
| Radio | `RadioSelect` | — |
| Hidden | `HiddenInput` | `hidden` |

## Anti-Patterns
- Using jQuery for widget interactivity — use Alpine.js
- Missing CSS classes on widgets — fields look unstyled
- Not setting `accept` attribute on file inputs — user can select wrong files
- Hard-coding widget classes in templates — set in form definition
- Missing `x-cloak` on Alpine.js conditional elements — causes FOUC

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Form Widgets](https://docs.djangoproject.com/en/5.2/ref/forms/widgets/)
- `templates/components/_form_field.html` — reusable form field component
