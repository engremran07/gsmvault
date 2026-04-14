---
name: alp-mask-currency
description: "Currency input masking. Use when: formatting monetary input, adding dollar signs and commas to amount fields, decimal precision enforcement."
---

# Alpine Currency Input Masking

## When to Use

- Price/amount input fields (shop, wallet, bounty)
- Credit/debit entry with auto-formatting
- Any monetary value that needs comma separation and decimal precision

## Patterns

### Basic Currency with x-mask:dynamic (Money)

```html
<input x-data x-mask:dynamic="$money($input)" type="text"
       placeholder="0.00" inputmode="decimal"
       class="w-full px-3 py-2 rounded border border-[var(--color-border)] bg-[var(--color-input)]">
```

### Currency with Symbol and Validation

```html
<div x-data="{ raw: '', get amount() { return parseFloat(this.raw.replace(/,/g, '')) || 0; } }">
  <div class="relative">
    <span class="absolute left-3 top-2.5 text-[var(--color-text-muted)]">$</span>
    <input x-model="raw" x-mask:dynamic="$money($input)"
           type="text" inputmode="decimal" placeholder="0.00"
           class="w-full pl-7 pr-3 py-2 rounded border border-[var(--color-border)] bg-[var(--color-input)]">
  </div>
  <p x-show="raw && amount <= 0" x-cloak class="text-sm text-red-500 mt-1">
    Enter a valid amount
  </p>
  <p x-show="amount > 0" x-cloak class="text-sm text-[var(--color-text-muted)] mt-1">
    Amount: $<span x-text="amount.toFixed(2)"></span>
  </p>
</div>
```

### Custom Precision (No Decimals)

```html
<input x-data x-mask:dynamic="$money($input, ',')" type="text"
       placeholder="1,000" inputmode="numeric"
       class="px-3 py-2 rounded border border-[var(--color-border)]">
```

### Credits/Points (Integer Only)

```html
<div x-data="{ credits: '' }">
  <input x-model="credits" x-mask:dynamic="$money($input, ',')"
         type="text" inputmode="numeric" placeholder="0"
         class="w-32 px-3 py-2 rounded border border-[var(--color-border)] bg-[var(--color-input)]">
  <span class="ml-2 text-[var(--color-text-muted)]">credits</span>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `type="number"` with mask | Conflicts with browser native controls | Use `type="text"` + `inputmode="decimal"` |
| Storing formatted string ("$1,234.56") | Can't do math | Parse to float before sending to server |
| No max amount validation | Users can enter absurd values | Validate server-side and optionally client-side |

## Red Flags

- Currency field without server-side validation of amount bounds
- Formatted currency string sent directly to the backend
- Missing `inputmode="decimal"` — mobile users don't get numpad

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
