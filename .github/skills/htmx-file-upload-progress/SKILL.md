---
name: htmx-file-upload-progress
description: "File upload progress tracking. Use when: showing upload percentage for large files, firmware upload progress bars, visual upload feedback."
---

# HTMX File Upload Progress

## When to Use

- Uploading large firmware files with progress indication
- Showing upload percentage bar to the user
- Any file upload where the user needs visual progress feedback

## Rules

1. Use `htmx:xhr:progress` event to track upload progress
2. Requires `hx-encoding="multipart/form-data"` on the form
3. Show progress bar component during upload
4. Disable the submit button during upload with `hx-disabled-elt`

## Patterns

### Upload Form with Progress Bar

```html
<div x-data="{ progress: 0, uploading: false }">
  <form hx-post="{% url 'firmwares:upload' %}"
        hx-encoding="multipart/form-data"
        hx-target="#upload-result"
        hx-disabled-elt="find button"
        @htmx:xhr:progress="progress = Math.round(event.detail.loaded / event.detail.total * 100); uploading = true"
        @htmx:afterRequest="uploading = false; progress = 0">

    <input type="file" name="firmware_file"
           accept=".zip,.rar,.pac,.bin,.img"
           required>

    <div x-show="uploading" x-cloak class="my-4">
      <div class="w-full bg-[var(--color-bg-tertiary)] rounded-full h-3">
        <div class="bg-[var(--color-accent)] h-3 rounded-full transition-all duration-200"
             :style="'width: ' + progress + '%'"></div>
      </div>
      <p class="text-sm text-center mt-1" x-text="progress + '%'"></p>
    </div>

    <button type="submit"
            class="btn btn-primary">
      <span x-show="!uploading">Upload Firmware</span>
      <span x-show="uploading" x-cloak>Uploading...</span>
    </button>
  </form>
  <div id="upload-result"></div>
</div>
```

### Event-Based Progress (JavaScript)

```html
<script nonce="{{ request.csp_nonce }}">
document.addEventListener('htmx:xhr:progress', function(event) {
  const pct = Math.round(event.detail.loaded / event.detail.total * 100);
  const bar = document.getElementById('upload-progress-bar');
  if (bar) {
    bar.style.width = pct + '%';
    bar.textContent = pct + '%';
  }
});
</script>
```

### With File Size Validation

```html
<div x-data="{ file: null, maxSize: 500 * 1024 * 1024 }">
  <input type="file" name="firmware_file"
         @change="file = $event.target.files[0]"
         accept=".zip,.rar,.pac,.bin">

  <template x-if="file && file.size > maxSize">
    <p class="text-red-500 text-sm">File exceeds 500MB limit</p>
  </template>

  <button type="submit"
          :disabled="!file || file.size > maxSize">
    Upload
  </button>
</div>
```

## Anti-Patterns

```html
<!-- WRONG — no progress indicator for large uploads -->
<form hx-post="/upload/" hx-encoding="multipart/form-data">
  <input type="file" name="file">
  <button>Upload</button>  <!-- user has no idea what's happening -->
</form>
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| No progress for large uploads | User thinks page is frozen | Add `htmx:xhr:progress` handler |
| No client-side file size check | 413 error after slow upload | Validate size in Alpine before submit |
| No `hx-disabled-elt` on submit | User submits multiple times | Disable button during upload |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
