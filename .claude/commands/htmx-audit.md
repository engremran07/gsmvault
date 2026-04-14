# /htmx-audit â€” HTMX pattern compliance audit

Audit HTMX usage across templates: fragment isolation, hx-target/hx-swap correctness, CSRF header propagation, and no-extends enforcement.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Fragment Isolation

- [ ] Scan all files in `templates/**/fragments/` directories

- [ ] Verify NO fragment uses `{% extends %}` â€” fragments are standalone snippets

- [ ] Verify fragments don't include `<html>`, `<head>`, or `<body>` tags

- [ ] Check fragments are minimal HTML suitable for DOM insertion

### Step 2: CSRF Header Propagation

- [ ] Verify `templates/base/base.html` has global `<body hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'>`

- [ ] Check no per-view or per-template CSRF handling that duplicates the global pattern

- [ ] Verify HTMX POST/PUT/DELETE requests inherit the CSRF token

### Step 3: hx-target / hx-swap Correctness

- [ ] Verify each `hx-get`/`hx-post` has corresponding `hx-target` pointing to existing DOM element

- [ ] Check `hx-swap` values are appropriate (innerHTML, outerHTML, beforeend, afterbegin)

- [ ] Verify targets use `#id` selectors, not class-based selectors

- [ ] Check for `hx-target="this"` patterns â€” ensure they make semantic sense

### Step 4: View Pattern Compliance

- [ ] Verify views check `request.headers.get("HX-Request")` to return fragment vs full page

- [ ] Check HX-Request views return fragment template, not full page template

- [ ] Verify non-HTMX fallback renders full page for progressive enhancement

### Step 5: hx-boost Prohibition

- [ ] Grep for `hx-boost` usage â€” it is prohibited in this codebase

- [ ] If found, replace with explicit `hx-get`/`hx-post` patterns

### Step 6: Error Handling

- [ ] Verify HTMX error responses return appropriate fragments (not full error pages)

- [ ] Check `hx-on::response-error` handlers exist for graceful degradation

- [ ] Verify 4xx/5xx responses from HTMX endpoints are user-friendly

### Step 7: Report

- [ ] List all non-compliant patterns with file:line references

- [ ] Categorize: breaking (functional issues), style (convention violations)

- [ ] Provide specific fix for each finding
