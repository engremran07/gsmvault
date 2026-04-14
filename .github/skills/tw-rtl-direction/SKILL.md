---
name: tw-rtl-direction
description: "Direction-aware layouts for RTL languages. Use when: building layouts that flip for Arabic/Hebrew, handling bidirectional text, RTL navigation."
---

# Direction-Aware Layouts

## When to Use

- Building layouts for Arabic, Hebrew, Persian, or Urdu users
- Setting the `dir` attribute based on locale
- Handling mixed LTR/RTL content in the same page

## Rules

1. **Set `dir` on `<html>` element** — Django template sets from locale
2. **Flexbox auto-flips in RTL** — no extra work needed for flex layouts
3. **Grid auto-flips** — grid-template-columns work correctly
4. **Images and media don't flip** — only layout direction changes
5. **Test with `dir="rtl"` added to `<html>`** — quick verification

## Patterns

### HTML Direction Setup

```html
<!-- templates/base/base.html -->
<html lang="{{ LANGUAGE_CODE }}" dir="{{ LANGUAGE_BIDI|yesno:'rtl,ltr' }}"
      data-theme="dark">
```

### Flex Layout (auto-flips)

```html
<!-- This layout automatically mirrors in RTL -->
<div class="flex items-center gap-4 p-4">
  <i data-lucide="smartphone" class="w-8 h-8 text-[var(--color-accent)]"></i>
  <div class="flex-1">
    <h3 class="text-[var(--color-text-primary)] font-medium">Samsung Galaxy S24</h3>
    <p class="text-sm text-[var(--color-text-secondary)]">Android 14</p>
  </div>
  <span class="text-[var(--color-status-success)] text-sm">Available</span>
</div>
```

### Navigation with RTL Chevrons

```html
<nav class="flex flex-col gap-1">
  <a href="#" class="flex items-center gap-3 px-4 py-2 rounded-lg
                     text-[var(--color-text-primary)]
                     hover:bg-[var(--color-bg-secondary)]">
    <i data-lucide="folder" class="w-5 h-5"></i>
    <span class="flex-1">Category</span>
    <!-- Chevron flips in RTL -->
    <i data-lucide="chevron-right" class="w-4 h-4 text-[var(--color-text-muted)]
                                          rtl:rotate-180"></i>
  </a>
</nav>
```

### Bidirectional Text Handling

```html
<!-- Auto-detect text direction for user-generated content -->
<p dir="auto" class="text-[var(--color-text-primary)]">
  {{ comment.text }}
</p>

<!-- Force LTR for code/technical content regardless of page direction -->
<code dir="ltr" class="font-mono text-sm bg-[var(--color-bg-secondary)]
                       text-[var(--color-accent)] px-1.5 py-0.5 rounded">
  pip install django
</code>
```

### RTL-Aware Breadcrumb

```html
<nav class="flex items-center gap-2 text-sm text-[var(--color-text-secondary)]">
  <a href="/" class="hover:text-[var(--color-accent)]">Home</a>
  <!-- Separator auto-flips via logical properties -->
  <i data-lucide="chevron-right" class="w-3 h-3 rtl:rotate-180"></i>
  <a href="/devices/" class="hover:text-[var(--color-accent)]">Devices</a>
  <i data-lucide="chevron-right" class="w-3 h-3 rtl:rotate-180"></i>
  <span class="text-[var(--color-text-primary)]">Samsung</span>
</nav>
```

### Content That Should NOT Flip

```html
<!-- Numbers, phone numbers, mathematical expressions stay LTR -->
<span dir="ltr" class="inline-block">+1 (555) 123-4567</span>
<span dir="ltr" class="inline-block font-mono">v2.4.1</span>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `float: left` for layout | Doesn't flip in RTL | Use flexbox |
| Manual `transform: scaleX(-1)` on layout | Hacky, breaks content | Use `dir="rtl"` properly |
| Hardcoded arrow characters `→` | Doesn't flip | Use Lucide icon with `rtl:rotate-180` |
| `dir="rtl"` on every element | Redundant, cascades from html | Set once on `<html>` |

## Red Flags

- Float-based layouts (don't flip in RTL)
- Directional arrow characters without RTL handling
- Missing `dir="ltr"` on code blocks, phone numbers, version strings
- Template hardcodes `dir="ltr"` on `<html>` instead of using locale

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `apps/i18n/` — internationalization utilities
- `templates/base/base.html` — dir attribute
