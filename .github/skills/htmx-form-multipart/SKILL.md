---
name: htmx-form-multipart
description: "File upload with HTMX using hx-encoding='multipart/form-data'. Use when: uploading files via HTMX forms, firmware uploads, avatar uploads, attachment handling."
---

# HTMX Multipart File Upload

## When to Use

- Uploading files (firmware, images, attachments) via HTMX without full page reload
- Avatar/profile image upload
- Forum attachment uploads
- Any form with `<input type="file">`

## Rules

1. Set `hx-encoding="multipart/form-data"` on the form or triggering element
2. Django receives files in `request.FILES` as usual
3. Validate MIME type, extension, and file size in the service layer
4. Use `hx-indicator` for upload progress feedback
5. Consider a separate progress endpoint for large files

## Patterns

### Basic File Upload Form

```html
<form hx-post="{% url 'firmwares:upload' %}"
      hx-encoding="multipart/form-data"
      hx-target="#upload-result"
      hx-indicator="#upload-spinner">
  <input type="file" name="firmware_file"
         accept=".zip,.rar,.pac,.bin"
         class="file-input">
  <button type="submit" hx-disabled-elt="this">
    Upload Firmware
  </button>
  <span id="upload-spinner" class="htmx-indicator">
    {% include "components/_loading.html" with size="sm" %}
  </span>
</form>
<div id="upload-result"></div>
```

### Django View Handling Upload

```python
from django.http import HttpResponse

def upload_firmware(request):
    if request.method != "POST":
        return HttpResponse(status=405)

    form = FirmwareUploadForm(request.POST, request.FILES)
    if form.is_valid():
        firmware = form.save(commit=False)
        firmware.uploaded_by = request.user
        firmware.save()
        return render(request, "firmwares/fragments/upload_success.html",
                      {"firmware": firmware})
    return render(request, "firmwares/fragments/upload_form.html",
                  {"form": form}, status=422)
```

### Image Preview Before Upload (Alpine.js)

```html
<div x-data="{ preview: null }">
  <form hx-post="{% url 'user_profile:update_avatar' %}"
        hx-encoding="multipart/form-data"
        hx-target="#avatar-area">
    <input type="file" name="avatar" accept="image/*"
           @change="preview = URL.createObjectURL($event.target.files[0])">
    <img x-show="preview" :src="preview" x-cloak
         class="w-24 h-24 rounded-full object-cover mt-2">
    <button type="submit">Upload Avatar</button>
  </form>
</div>
```

## Anti-Patterns

```html
<!-- WRONG — missing hx-encoding (files won't be sent) -->
<form hx-post="/upload/">
  <input type="file" name="file">
  <button type="submit">Upload</button>
</form>

<!-- WRONG — no file validation on server -->
<!-- Always validate MIME, extension, size before saving -->
```

## Red Flags

| Signal | Problem | Fix |
|--------|---------|-----|
| Missing `hx-encoding` | `request.FILES` is empty | Add `hx-encoding="multipart/form-data"` |
| No file size validation | Disk exhaustion attack | Validate in form/service layer |
| No MIME type validation | Disguised executable upload | Check MIME type before saving |
| No upload indicator | User resubmits during upload | Add `hx-indicator` + `hx-disabled-elt` |

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
