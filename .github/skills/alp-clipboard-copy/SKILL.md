---
name: alp-clipboard-copy
description: "Copy-to-clipboard functionality. Use when: copy buttons for codes/URLs/snippets, share links, download links, API keys display."
---

# Alpine Copy to Clipboard

## When to Use

- Copy-to-clipboard button for download links, referral codes, API keys
- Share URL copy button
- Code snippet copy in documentation or forum posts

## Patterns

### Basic Copy Button

```html
<div x-data="{ copied: false }">
  <div class="flex items-center gap-2">
    <input type="text" readonly value="{{ download_url }}" x-ref="copyInput"
           class="flex-1 px-3 py-2 rounded border border-[var(--color-border)] bg-[var(--color-surface-alt)] text-sm">
    <button @click="
      navigator.clipboard.writeText($refs.copyInput.value).then(() => {
        copied = true;
        setTimeout(() => copied = false, 2000);
      })
    " class="px-3 py-2 rounded bg-[var(--color-accent)] text-[var(--color-accent-text)]">
      <span x-show="!copied">Copy</span>
      <span x-show="copied" x-cloak>Copied!</span>
    </button>
  </div>
</div>
```

### Copy with Icon Swap

```html
<div x-data="{ copied: false }">
  <button @click="
    navigator.clipboard.writeText('{{ referral_code }}').then(() => {
      copied = true;
      setTimeout(() => copied = false, 2000);
    })
  " class="inline-flex items-center gap-1 text-sm text-[var(--color-accent)]">
    <template x-if="!copied">
      <span>{% include 'components/_icon.html' with name='copy' size='16' %} Copy Code</span>
    </template>
    <template x-if="copied">
      <span>{% include 'components/_icon.html' with name='check' size='16' %} Copied!</span>
    </template>
  </button>
</div>
```

### Copy Arbitrary Text (No Input)

```html
<div x-data="{ copied: false }">
  <pre class="p-4 rounded bg-[var(--color-surface-alt)] text-sm overflow-x-auto"><code x-ref="code">pip install firmware-tools</code></pre>
  <button @click="
    navigator.clipboard.writeText($refs.code.textContent.trim()).then(() => {
      copied = true;
      setTimeout(() => copied = false, 2000);
    })
  " class="mt-2 text-xs text-[var(--color-text-muted)] hover:text-[var(--color-accent)]">
    <span x-text="copied ? 'Copied!' : 'Copy command'"></span>
  </button>
</div>
```

### Fallback for Older Browsers

```html
<div x-data="{
  copied: false,
  copyText(text) {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(text).then(() => this.showCopied());
    } else {
      const ta = document.createElement('textarea');
      ta.value = text;
      ta.style.position = 'fixed';
      ta.style.opacity = '0';
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);
      this.showCopied();
    }
  },
  showCopied() {
    this.copied = true;
    setTimeout(() => this.copied = false, 2000);
  }
}">
  <button @click="copyText('{{ share_url }}')"
          class="px-3 py-1 rounded border border-[var(--color-border)]">
    <span x-text="copied ? 'Copied!' : 'Share Link'"></span>
  </button>
</div>
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| No user feedback after copy | User unsure if it worked | Show "Copied!" state for 2s |
| Using `document.execCommand('copy')` only | Deprecated, fails in some contexts | Use `navigator.clipboard` with fallback |
| Copy button without `readonly` input | User can accidentally edit | Add `readonly` attribute |

## Red Flags

- No visual confirmation (icon/text change) after copying
- `navigator.clipboard` used without HTTPS context check
- Missing fallback for insecure contexts (HTTP localhost is fine)

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
