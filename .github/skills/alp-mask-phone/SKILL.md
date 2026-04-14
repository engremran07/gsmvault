---
name: alp-mask-phone
description: "Phone number masking. Use when: formatting phone input fields, auto-formatting international phone numbers, masking mobile number entry."
---

# Alpine Phone Number Masking

## When to Use

- Phone number input fields in registration, profile, contact forms
- Auto-formatting as user types (parentheses, dashes, spaces)
- Supporting international format variations

## Patterns

### US Phone Format

```html
<input x-data x-mask="(999) 999-9999" type="tel"
       placeholder="(555) 123-4567"
       class="w-full px-3 py-2 rounded border border-[var(--color-border)] bg-[var(--color-input)]">
```

### International with Country Code

```html
<input x-data x-mask="+99 999 999 9999" type="tel"
       placeholder="+1 555 123 4567"
       class="w-full px-3 py-2 rounded border border-[var(--color-border)]">
```

### Dynamic Mask Based on Country

```html
<div x-data="{ country: 'US' }">
  <select x-model="country" class="px-3 py-2 rounded border border-[var(--color-border)]">
    <option value="US">US (+1)</option>
    <option value="UK">UK (+44)</option>
    <option value="DE">DE (+49)</option>
  </select>
  <input x-mask:dynamic="
    country === 'US' ? '(999) 999-9999' :
    country === 'UK' ? '+44 9999 999 999' :
    '+49 999 9999999'
  " type="tel" placeholder="Phone number"
    class="w-full px-3 py-2 rounded border border-[var(--color-border)]">
</div>
```

### Phone with Validation Feedback

```html
<div x-data="{ phone: '', get isValid() { return this.phone.replace(/\D/g, '').length >= 10; } }">
  <div class="relative">
    <input x-model="phone" x-mask="(999) 999-9999" type="tel"
           placeholder="(555) 123-4567"
           :class="{ 'border-green-500': isValid, 'border-[var(--color-border)]': !isValid }"
           class="w-full px-3 py-2 rounded border bg-[var(--color-input)]">
    <span x-show="isValid" x-cloak class="absolute right-3 top-2.5 text-green-500">✓</span>
  </div>
  <p x-show="phone.length > 0 && !isValid" x-cloak class="text-sm text-red-500 mt-1">
    Enter a complete phone number
  </p>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Single mask for all countries | Rejects valid international numbers | Use dynamic mask per country |
| Storing formatted value server-side | Inconsistent data | Strip formatting before saving |
| No `type="tel"` | Mobile doesn't show numpad keyboard | Always use `type="tel"` |

## Red Flags

- Phone mask without server-side validation
- Formatted phone number stored in database instead of digits-only
- Missing `type="tel"` attribute on phone inputs

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
