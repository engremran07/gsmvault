---
name: tw-forms-styling
description: "Form element styling: inputs, selects, checkboxes, radios. Use when: styling form controls, creating themed form inputs, building form layouts."
---

# Form Element Styling

## When to Use

- Styling form inputs, selects, textareas
- Building form layouts with consistent styling
- Creating theme-aware form components

## Rules

1. **All form elements use CSS custom properties** — theme-aware colours
2. **Use `{% include "components/_form_field.html" %}`** — never inline form field styling
3. **Focus rings use accent colour** — `focus:ring-[var(--color-accent)]`
4. **Consistent border radius** — `rounded-md` for inputs, `rounded-lg` for groups
5. **Accessible labels** — every input must have a `<label>` or `aria-label`

## Patterns

### Standard Text Input

```html
<label for="email" class="block text-sm font-medium
                          text-[var(--color-text-primary)] mb-1">
  Email Address
</label>
<input type="email" id="email" name="email"
       class="w-full rounded-md px-3 py-2
              bg-[var(--color-bg-input)] text-[var(--color-text-primary)]
              border border-[var(--color-border)]
              focus:outline-none focus:ring-2
              focus:ring-[var(--color-accent)] focus:border-[var(--color-accent)]
              placeholder:text-[var(--color-text-muted)]"
       placeholder="you@example.com">
```

### Select Dropdown

```html
<select class="w-full rounded-md px-3 py-2
               bg-[var(--color-bg-input)] text-[var(--color-text-primary)]
               border border-[var(--color-border)]
               focus:outline-none focus:ring-2
               focus:ring-[var(--color-accent)] focus:border-[var(--color-accent)]">
  <option value="">Choose brand...</option>
  {% for brand in brands %}
  <option value="{{ brand.pk }}">{{ brand.name }}</option>
  {% endfor %}
</select>
```

### Checkbox & Radio

```html
<!-- Checkbox -->
<label class="inline-flex items-center gap-2 cursor-pointer">
  <input type="checkbox" name="agree"
         class="h-4 w-4 rounded border-[var(--color-border)]
                bg-[var(--color-bg-input)]
                text-[var(--color-accent)]
                focus:ring-[var(--color-accent)] focus:ring-2">
  <span class="text-sm text-[var(--color-text-primary)]">I agree to terms</span>
</label>

<!-- Radio -->
<label class="inline-flex items-center gap-2 cursor-pointer">
  <input type="radio" name="tier" value="free"
         class="h-4 w-4 border-[var(--color-border)]
                bg-[var(--color-bg-input)]
                text-[var(--color-accent)]
                focus:ring-[var(--color-accent)] focus:ring-2">
  <span class="text-sm text-[var(--color-text-primary)]">Free Tier</span>
</label>
```

### Textarea

```html
<textarea rows="4"
          class="w-full rounded-md px-3 py-2 resize-y
                 bg-[var(--color-bg-input)] text-[var(--color-text-primary)]
                 border border-[var(--color-border)]
                 focus:outline-none focus:ring-2
                 focus:ring-[var(--color-accent)] focus:border-[var(--color-accent)]
                 placeholder:text-[var(--color-text-muted)]"
          placeholder="Enter description..."></textarea>
```

### Form Layout

```html
<form method="post" class="space-y-6 max-w-xl">
  {% csrf_token %}
  <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
    {% include "components/_form_field.html" with field=form.first_name %}
    {% include "components/_form_field.html" with field=form.last_name %}
  </div>
  {% include "components/_form_field.html" with field=form.email %}
  <button type="submit"
          class="w-full bg-[var(--color-accent)] text-[var(--color-accent-text)]
                 py-2.5 px-4 rounded-lg font-medium
                 hover:bg-[var(--color-accent-hover)]
                 focus:outline-none focus:ring-2 focus:ring-[var(--color-accent)]
                 focus:ring-offset-2">
    Submit
  </button>
</form>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `bg-white` on inputs | Not theme-aware | `bg-[var(--color-bg-input)]` |
| Missing focus ring | Keyboard users can't see focus | Add `focus:ring-2` |
| Input without label | Accessibility violation | Add `<label>` or `aria-label` |
| Inline form field styling | Should use component | `{% include "components/_form_field.html" %}` |

## Red Flags

- Form inputs without `focus:ring-*` or `focus:outline-*` styles
- Missing `{% csrf_token %}` in forms
- Hardcoded colours on form elements

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `templates/components/_form_field.html` — reusable form field component
- `templates/components/_field_error.html` — field error display
- `.claude/rules/forms-layer.md` — form rules
