---
name: tw-rtl-logical-properties
description: "RTL support with logical properties: inline-start/end. Use when: supporting RTL languages, using logical margins/padding, bidirectional layout."
---

# RTL Support with Logical Properties

## When to Use

- Adding RTL (right-to-left) language support
- Writing layout code that works in both LTR and RTL
- Replacing directional properties with logical equivalents

## Rules

1. **Use logical properties over physical** — `ms-4` not `ml-4` when direction matters
2. **`dir="rtl"` on `<html>`** — set by i18n system, not hardcoded
3. **Test both directions** — validate layout in LTR and RTL
4. **Flexbox and Grid are already logical** — `flex-row` stays correct in RTL
5. **Icons and arrows may need flipping** — chevrons, back arrows

## Patterns

### Logical Property Mapping

| Physical (LTR only) | Logical (LTR + RTL) | Tailwind Class |
|---------------------|---------------------|----------------|
| `margin-left` | `margin-inline-start` | `ms-4` |
| `margin-right` | `margin-inline-end` | `me-4` |
| `padding-left` | `padding-inline-start` | `ps-4` |
| `padding-right` | `padding-inline-end` | `pe-4` |
| `left` | `inset-inline-start` | `start-0` |
| `right` | `inset-inline-end` | `end-0` |
| `text-left` | `text-start` | `text-start` |
| `text-right` | `text-end` | `text-end` |
| `border-left` | `border-inline-start` | `border-s` |
| `border-right` | `border-inline-end` | `border-e` |

### RTL-Safe Navigation Item

```html
<!-- Uses logical properties — works in both LTR and RTL -->
<a href="#" class="flex items-center gap-2 ps-4 pe-3 py-2
                   text-[var(--color-text-primary)]
                   hover:bg-[var(--color-bg-secondary)] rounded-lg">
  <i data-lucide="home" class="w-5 h-5"></i>
  <span>Home</span>
  <!-- Arrow auto-flips via logical positioning -->
  <i data-lucide="chevron-right" class="w-4 h-4 ms-auto
                                        rtl:rotate-180"></i>
</a>
```

### RTL-Safe Card Layout

```html
<div class="flex items-start gap-4 p-4
            bg-[var(--color-bg-secondary)] rounded-lg">
  <!-- Avatar on start side -->
  <img src="/avatar.jpg" alt="" class="w-10 h-10 rounded-full flex-shrink-0">

  <!-- Content fills remaining space -->
  <div class="flex-1 min-w-0">
    <h3 class="text-start text-[var(--color-text-primary)] font-medium">
      Username
    </h3>
    <p class="text-start text-sm text-[var(--color-text-secondary)]">
      Comment text that aligns correctly in both directions.
    </p>
  </div>

  <!-- Action button on end side -->
  <button class="ms-auto flex-shrink-0 text-[var(--color-text-muted)]">
    <i data-lucide="more-vertical" class="w-4 h-4"></i>
  </button>
</div>
```

### RTL-Safe Form Labels

```html
<div class="flex flex-col gap-1">
  <label class="text-start text-sm font-medium
                text-[var(--color-text-primary)]">
    Email Address
  </label>
  <input type="email" dir="auto"
         class="w-full rounded-md px-3 py-2 text-start
                bg-[var(--color-bg-input)] text-[var(--color-text-primary)]
                border border-[var(--color-border)]">
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `ml-4` for spacing from icon | Breaks in RTL | `ms-4` |
| `text-left` for content alignment | Wrong in RTL | `text-start` |
| `left-0 absolute` | Appears on wrong side in RTL | `start-0 absolute` |
| `pl-4 pr-2` on nav items | Reversed padding in RTL | `ps-4 pe-2` |

## Red Flags

- `ml-*`, `mr-*`, `pl-*`, `pr-*` where direction matters (use `ms-*`, `me-*`, `ps-*`, `pe-*`)
- `text-left`/`text-right` instead of `text-start`/`text-end`
- Hardcoded `left:`/`right:` on positioned elements
- Directional icons (arrows, chevrons) without `rtl:rotate-180`

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `apps/i18n/` — internationalization utilities
- `templates/base/base.html` — `dir` attribute on `<html>`
