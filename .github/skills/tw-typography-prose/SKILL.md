---
name: tw-typography-prose
description: "Typography: prose class, font loading, text sizing. Use when: styling long-form content, blog posts, article pages, rich text rendering."
---

# Typography and Prose

## When to Use

- Rendering user-generated or editor-generated HTML content
- Styling blog posts, articles, documentation pages
- Setting up consistent text sizing and line height

## Rules

1. **Use `prose` class for long-form content** — provides sensible defaults for headings, lists, code
2. **Override prose colours with CSS custom properties** — not hardcoded Tailwind colours
3. **Font stack: Inter (sans), JetBrains Mono (code)** — loaded as WOFF2
4. **Line height: at least 1.5 for body text** — accessibility requirement
5. **Max prose width: `prose-lg max-w-3xl`** — readable line lengths

## Patterns

### Blog Post Content

```html
<article class="prose prose-lg max-w-3xl mx-auto
                text-[var(--color-text-primary)]
                prose-headings:text-[var(--color-text-primary)]
                prose-a:text-[var(--color-accent)]
                prose-a:hover:text-[var(--color-accent-hover)]
                prose-strong:text-[var(--color-text-primary)]
                prose-code:text-[var(--color-accent)]
                prose-code:bg-[var(--color-bg-secondary)]
                prose-code:px-1.5 prose-code:py-0.5 prose-code:rounded">
  {{ post.content|safe }}
</article>
```

### Text Size Scale

| Class | Size | Use |
|-------|------|-----|
| `text-xs` | 0.75rem | Captions, fine print |
| `text-sm` | 0.875rem | Secondary text, labels |
| `text-base` | 1rem | Body text |
| `text-lg` | 1.125rem | Emphasis, intro text |
| `text-xl` | 1.25rem | Section headings |
| `text-2xl` | 1.5rem | Page sub-headings |
| `text-3xl` | 1.875rem | Page headings |
| `text-4xl` | 2.25rem | Hero headings |

### Consistent Heading Style

```html
<h1 class="text-3xl md:text-4xl font-bold tracking-tight
           text-[var(--color-text-primary)]">Page Title</h1>
<h2 class="text-xl md:text-2xl font-semibold mt-8 mb-4
           text-[var(--color-text-primary)]">Section</h2>
<p class="text-base leading-relaxed text-[var(--color-text-secondary)]">
  Body paragraph with comfortable line height for readability.
</p>
```

### Code and Monospace

```html
<code class="font-mono text-sm bg-[var(--color-bg-secondary)]
             text-[var(--color-accent)] px-1.5 py-0.5 rounded">
  manage.py runserver
</code>

<pre class="font-mono text-sm bg-[var(--color-bg-secondary)]
            text-[var(--color-text-primary)] p-4 rounded-lg overflow-x-auto">
  <code>pip install django</code>
</pre>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `prose-gray` | Not theme-aware | Use CSS custom property overrides |
| Line height below 1.4 | Readability issue | Use `leading-relaxed` (1.625) or `leading-normal` (1.5) |
| Prose without max-width | Lines too long on wide screens | `max-w-3xl` or `max-w-prose` |
| `font-sans` hardcoded | Missing project fonts | Use `font-[var(--font-sans)]` |

## Red Flags

- `prose` class without colour overrides in themed context
- Blog content without `prose` styling
- Missing `overflow-x-auto` on `<pre>` blocks

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References

- `static/fonts/` — WOFF2 font files
- `static/css/src/main.scss` — font-face declarations
- `templates/blog/post_detail.html` — prose usage example
