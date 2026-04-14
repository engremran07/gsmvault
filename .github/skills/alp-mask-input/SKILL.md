---
name: alp-mask-input
description: "Input masking with x-mask. Use when: formatting user input in text fields, constraining input to specific patterns, auto-formatting dates or codes."
---

# Alpine Input Masking

## When to Use

- Formatting date inputs (DD/MM/YYYY)
- Serial number / product code entry
- Any input requiring a fixed character pattern

## Patterns

### Basic Date Mask

Requires `@alpinejs/mask` plugin:

```html
<input x-data x-mask="99/99/9999" type="text" placeholder="DD/MM/YYYY"
       class="w-full px-3 py-2 rounded border border-[var(--color-border)] bg-[var(--color-input)]">
```

### Dynamic Mask with x-mask:dynamic

```html
<input x-data x-mask:dynamic="
  $input.startsWith('3') ? '9999 999999 99999' : '9999 9999 9999 9999'
" type="text" placeholder="Card number"
  class="w-full px-3 py-2 rounded border border-[var(--color-border)]">
```

### Postal Code / ZIP

```html
<input x-data x-mask="99999" type="text" placeholder="ZIP Code"
       class="w-32 px-3 py-2 rounded border border-[var(--color-border)]">
```

### Custom Pattern with x-model

```html
<div x-data="{ code: '' }">
  <input x-model="code" x-mask="AAA-9999" type="text"
         placeholder="ABC-1234"
         class="px-3 py-2 rounded border border-[var(--color-border)]">
  <span x-show="code.length === 8" x-cloak class="text-green-500">✓ Valid</span>
</div>
```

## Mask Characters

| Char | Matches |
|------|---------|
| `9` | Digits 0-9 |
| `a` | Letters a-z (case insensitive) |
| `*` | Any alphanumeric |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Server-side validation only | Bad UX — user sees error after submit | Add mask for instant feedback |
| Complex regex validation instead of mask | Harder to maintain | Use `x-mask` for pattern, validate on submit |
| Mask without placeholder text | User doesn't know expected format | Always include `placeholder` |

## Red Flags

- `x-mask` plugin not loaded (check CDN fallback chain includes `@alpinejs/mask`)
- Input mask without corresponding server-side validation
- Mask that prevents valid input (e.g., international formats)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
