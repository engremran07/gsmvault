---
paths: ["apps/*/forms.py"]
---

# Forms Layer Rules

Django forms are the primary input validation boundary. All user-supplied data MUST pass through form validation before reaching services or models.

## Field Declaration

- ModelForms MUST declare an explicit `fields` list — NEVER use `fields = "__all__"`.
- Exclude sensitive fields (`user`, `created_at`, `is_active`, `is_staff`) from form `fields`.
- Set `widgets` in `Meta` for textarea, date pickers, select2, and file inputs.
- Use `help_text` on fields that need user guidance.
- ALWAYS set `required=True/False` explicitly on ambiguous fields.

## Input Validation

- NEVER trust client-side validation alone — all validation MUST happen server-side in the form.
- Override `clean_<fieldname>()` for field-level validation.
- Override `clean()` for cross-field validation.
- Raise `ValidationError` with user-readable messages and error codes.
- ALWAYS sanitize HTML content with `apps.core.sanitizers.sanitize_html_content()` in `clean_<field>()` methods.

## File Upload Validation

- ALWAYS validate MIME type against an allowlist in `clean_<filefield>()`.
- ALWAYS validate file extension against an allowlist.
- ALWAYS enforce file size limits — reject oversized files before processing.
- NEVER rely on file extension alone for type detection — check magic bytes or MIME.
- Store uploaded files through the storage service layer, not directly to disk.

## Security

- CSRF protection is handled globally by `<body hx-headers>` for HTMX and `{% csrf_token %}` for standard forms — NEVER add `@csrf_exempt` to form-handling views.
- Form action URLs MUST use `{% url %}` template tag — NEVER hardcode paths.
- Sensitive forms (password change, email change, payment) MUST re-verify authentication.
- Rate-limit form submissions on authentication forms — use `apps.core.throttling` classes.

## Template Rendering

- Use `{% include "components/_form_field.html" %}` to render individual form fields.
- Use `{% include "components/_form_errors.html" %}` for form-level error summaries.
- Use `{% include "components/_field_error.html" %}` for field-level errors.
- NEVER manually construct `<input>` tags for form fields — use Django's form rendering.

## Form Processing in Views

- Handle GET (display empty/prepopulated form) and POST (validate + process) in the same view.
- On successful POST: call the service function, then redirect (POST-redirect-GET pattern).
- On validation failure: re-render the form with errors — NEVER redirect on failure.
- Pass `request.FILES` alongside `request.POST` for forms with file uploads.
