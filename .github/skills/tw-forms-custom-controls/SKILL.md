---
name: tw-forms-custom-controls
description: "Custom form controls: toggles, range sliders, date pickers. Use when: building toggle switches, custom sliders, datepicker inputs, styled file uploads."
---

# Custom Form Controls

## When to Use

- Building toggle switches for boolean settings
- Creating styled range/slider inputs
- Customizing file upload buttons
- Adding custom date/time pickers

## Rules

1. **Keep native semantics** — always use real `<input>` underneath for accessibility
2. **Theme-aware colours** — use CSS custom properties for all colours
3. **Keyboard accessible** — all custom controls must work with keyboard
4. **Focus visible** — show focus ring on keyboard navigation

## Patterns

### Toggle Switch

```html
<label class="inline-flex items-center gap-3 cursor-pointer">
  <span class="text-sm text-[var(--color-text-primary)]">Notifications</span>
  <div class="relative" x-data="{ on: false }">
    <input type="checkbox" name="notifications" class="sr-only peer"
           x-model="on" :checked="on">
    <div class="w-11 h-6 rounded-full transition-colors
                bg-[var(--color-border)] peer-checked:bg-[var(--color-accent)]
                peer-focus-visible:ring-2 peer-focus-visible:ring-[var(--color-accent)]
                peer-focus-visible:ring-offset-2"></div>
    <div class="absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white
                transition-transform peer-checked:translate-x-5
                shadow-sm"></div>
  </div>
</label>
```

### Range Slider

```html
<div x-data="{ value: 50 }">
  <label class="block text-sm font-medium text-[var(--color-text-primary)] mb-2">
    Download Limit: <span x-text="value + '%'" class="text-[var(--color-accent)]"></span>
  </label>
  <input type="range" min="0" max="100" x-model="value"
         class="w-full h-2 rounded-lg cursor-pointer
                appearance-none bg-[var(--color-border)]
                accent-[var(--color-accent)]
                focus:outline-none focus:ring-2
                focus:ring-[var(--color-accent)] focus:ring-offset-2">
</div>
```

### Custom File Upload

```html
<div x-data="{ filename: '' }">
  <label class="flex items-center justify-center gap-2 px-4 py-3
                rounded-lg border-2 border-dashed
                border-[var(--color-border)]
                bg-[var(--color-bg-secondary)]
                text-[var(--color-text-secondary)]
                hover:border-[var(--color-accent)]
                hover:text-[var(--color-accent)]
                cursor-pointer transition-colors">
    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"/>
    </svg>
    <span x-text="filename || 'Choose file...'" x-cloak></span>
    <input type="file" class="sr-only"
           @change="filename = $event.target.files[0]?.name || ''">
  </label>
</div>
```

### Styled Number Input

```html
<div class="flex items-center gap-2" x-data="{ qty: 1 }">
  <button @click="qty = Math.max(1, qty - 1)" type="button"
          class="w-8 h-8 rounded-md flex items-center justify-center
                 bg-[var(--color-bg-secondary)] text-[var(--color-text-primary)]
                 border border-[var(--color-border)]
                 hover:bg-[var(--color-accent)] hover:text-[var(--color-accent-text)]">
    −
  </button>
  <input type="number" x-model="qty" min="1" max="99"
         class="w-16 text-center rounded-md py-1
                bg-[var(--color-bg-input)] text-[var(--color-text-primary)]
                border border-[var(--color-border)]
                focus:ring-2 focus:ring-[var(--color-accent)]">
  <button @click="qty = Math.min(99, qty + 1)" type="button"
          class="w-8 h-8 rounded-md flex items-center justify-center
                 bg-[var(--color-bg-secondary)] text-[var(--color-text-primary)]
                 border border-[var(--color-border)]
                 hover:bg-[var(--color-accent)] hover:text-[var(--color-accent-text)]">
    +
  </button>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `<div>` pretending to be toggle | Not accessible | Use real `<input type="checkbox">` with `sr-only` |
| Custom slider without `<input type="range">` | Breaks forms, no keyboard | Use native `<input>` with styled overlay |
| File upload without `<input type="file">` | Can't actually upload | Native input with `sr-only`, style the label |

## Red Flags

- Custom controls without `sr-only` native input
- Missing keyboard interaction (Tab/Space/Enter)
- No focus-visible styling on custom controls
- Missing `x-cloak` on Alpine.js conditional content

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `templates/components/_form_field.html` — form field component
- `.claude/rules/alpine-patterns.md` — Alpine.js rules
