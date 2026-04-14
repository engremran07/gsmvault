---
name: tw-forms-validation-states
description: "Validation states: error, success, disabled styling. Use when: showing form validation feedback, error borders, success indicators, disabled inputs."
---

# Form Validation States

## When to Use

- Displaying validation errors on form fields
- Showing success state after valid input
- Styling disabled/readonly form fields
- Using `{% include "components/_field_error.html" %}` with Django forms

## Rules

1. **Error: red border + error message below** — `border-[var(--color-status-error)]`
2. **Success: green border** — `border-[var(--color-status-success)]` (optional)
3. **Disabled: reduced opacity + not-allowed cursor** — `opacity-50 cursor-not-allowed`
4. **Use `{% include "components/_field_error.html" %}`** — never inline error HTML
5. **Error messages use `--color-status-error`** — not hardcoded red

## Patterns

### Error State

```html
<div>
  <label class="block text-sm font-medium text-[var(--color-text-primary)] mb-1">
    Email
  </label>
  <input type="email"
         class="w-full rounded-md px-3 py-2
                bg-[var(--color-bg-input)] text-[var(--color-text-primary)]
                border-2 border-[var(--color-status-error)]
                focus:ring-2 focus:ring-[var(--color-status-error)]"
         value="invalid-email" aria-invalid="true" aria-describedby="email-error">
  <p id="email-error" class="mt-1 text-sm text-[var(--color-status-error)]">
    Please enter a valid email address.
  </p>
</div>
```

### Success State

```html
<div>
  <label class="block text-sm font-medium text-[var(--color-text-primary)] mb-1">
    Username
  </label>
  <div class="relative">
    <input type="text"
           class="w-full rounded-md px-3 py-2 pr-10
                  bg-[var(--color-bg-input)] text-[var(--color-text-primary)]
                  border-2 border-[var(--color-status-success)]
                  focus:ring-2 focus:ring-[var(--color-status-success)]"
           value="john_doe" aria-invalid="false">
    <span class="absolute right-3 top-1/2 -translate-y-1/2
                 text-[var(--color-status-success)]">✓</span>
  </div>
</div>
```

### Disabled State

```html
<input type="text" disabled
       class="w-full rounded-md px-3 py-2
              bg-[var(--color-bg-input)] text-[var(--color-text-muted)]
              border border-[var(--color-border)]
              opacity-50 cursor-not-allowed"
       value="Cannot edit">
```

### Django Form Integration

```html
{% for field in form %}
<div class="mb-4">
  <label for="{{ field.id_for_label }}"
         class="block text-sm font-medium text-[var(--color-text-primary)] mb-1">
    {{ field.label }}
  </label>
  <input type="{{ field.field.widget.input_type|default:'text' }}"
         name="{{ field.html_name }}"
         value="{{ field.value|default:'' }}"
         class="w-full rounded-md px-3 py-2
                bg-[var(--color-bg-input)] text-[var(--color-text-primary)]
                border {% if field.errors %}border-2 border-[var(--color-status-error)]
                {% else %}border-[var(--color-border)]{% endif %}
                focus:ring-2 focus:ring-[var(--color-accent)]"
         {% if field.errors %}aria-invalid="true"{% endif %}>
  {% if field.errors %}
    {% include "components/_field_error.html" with errors=field.errors %}
  {% endif %}
</div>
{% endfor %}
```

### Form-Level Error Summary

```html
{% if form.non_field_errors %}
  {% include "components/_form_errors.html" with errors=form.non_field_errors %}
{% endif %}
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `border-red-500` for errors | Not theme-aware | `border-[var(--color-status-error)]` |
| Error text without `aria-invalid` | Inaccessible | Add `aria-invalid="true"` to input |
| Custom inline error HTML | Inconsistent | Use `_field_error.html` component |
| `disabled` without visual indicator | Confusing | Add `opacity-50 cursor-not-allowed` |

## Red Flags

- Form fields with `aria-invalid` but no visible error message
- Error messages not associated via `aria-describedby`
- Mixed error styling patterns across forms

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `templates/components/_field_error.html` — field error component
- `templates/components/_form_errors.html` — form-level error summary
- `.claude/rules/forms-layer.md` — form rules
