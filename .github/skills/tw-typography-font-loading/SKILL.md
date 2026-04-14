---
name: tw-typography-font-loading
description: "Font loading: WOFF2, font-display, preload. Use when: adding custom fonts, optimizing font loading, preventing FOIT/FOUT."
---

# Font Loading Strategy

## When to Use

- Adding or changing custom fonts
- Optimizing web font loading performance
- Debugging font display issues (FOIT/FOUT)

## Rules

1. **WOFF2 only** — best compression, universal support
2. **`font-display: swap`** — shows fallback text immediately, swaps when loaded
3. **Preload critical fonts** — in `<head>` with `rel="preload"`
4. **Maximum 2 font families** — Inter (sans) and JetBrains Mono (mono)
5. **Subset if possible** — latin + latin-extended for smallest file size

## Patterns

### @font-face Declaration

```scss
/* static/css/src/_fonts.scss */
@font-face {
  font-family: 'Inter';
  src: url('/static/fonts/Inter-Regular.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: 'Inter';
  src: url('/static/fonts/Inter-SemiBold.woff2') format('woff2');
  font-weight: 600;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: 'Inter';
  src: url('/static/fonts/Inter-Bold.woff2') format('woff2');
  font-weight: 700;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: 'JetBrains Mono';
  src: url('/static/fonts/JetBrainsMono-Regular.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}
```

### Preload in HTML Head

```html
<head>
  <!-- Preload critical fonts -->
  <link rel="preload" href="{% static 'fonts/Inter-Regular.woff2' %}"
        as="font" type="font/woff2" crossorigin>
  <link rel="preload" href="{% static 'fonts/Inter-SemiBold.woff2' %}"
        as="font" type="font/woff2" crossorigin>
</head>
```

### Font Stack CSS Custom Properties

```scss
:root {
  --font-sans: 'Inter', system-ui, -apple-system, BlinkMacSystemFont,
               'Segoe UI', Roboto, sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, 'Cascadia Code',
               'Fira Code', monospace;
}
```

### Usage in Templates

```html
<body class="font-[var(--font-sans)] text-base
             text-[var(--color-text-primary)]
             bg-[var(--color-bg-primary)]">
  <code class="font-[var(--font-mono)] text-sm">monospace text</code>
</body>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| TTF/OTF fonts in production | Larger files, slower | Convert to WOFF2 |
| `font-display: block` | Invisible text while loading (FOIT) | `font-display: swap` |
| Preloading all font weights | Wastes bandwidth | Preload only 400 and 600 |
| Google Fonts `<link>` | External dependency, privacy | Self-host WOFF2 files |
| Missing `crossorigin` on preload | Preload ignored by browser | Add `crossorigin` attribute |

## Red Flags

- Font files in formats other than WOFF2
- Missing `font-display` property in @font-face
- More than 4 font files preloaded
- Fonts loaded from external CDNs

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `static/fonts/` — WOFF2 font files
- `templates/base/base.html` — preload tags
- `static/css/src/main.scss` — @font-face declarations
