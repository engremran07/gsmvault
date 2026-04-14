# /xss-audit â€” XSS vulnerability audit

Comprehensive audit for cross-site scripting vulnerabilities: unsanitized user input, unsafe template filters, missing nh3 sanitization, and template injection risks.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Template |safe Filter Audit

- [ ] Grep all templates for `|safe` usage

- [ ] For each `|safe`, trace the variable back to verify upstream sanitization via `sanitize_html_content()`

- [ ] Flag any `|safe` on user-supplied data without sanitization

- [ ] Check `|escapejs` is used for JS string interpolation

### Step 2: mark_safe() Audit

- [ ] Grep Python code for `mark_safe()` usage

- [ ] Verify each call operates on trusted/sanitized content only

- [ ] Flag any `mark_safe()` on user input or database content without sanitization

### Step 3: nh3 Sanitization

- [ ] Verify `apps.core.sanitizers.sanitize_html_content()` uses nh3 (NOT bleach)

- [ ] Check all user-generated HTML fields (blog posts, comments, forum replies, bio, ad code) pass through sanitization

- [ ] Verify sanitization happens in service layer, not view layer

- [ ] Check `sanitize_ad_code()` for ad content

### Step 4: Template Injection

- [ ] Check for any dynamic template rendering from user input

- [ ] Verify no `Template(user_string)` patterns

- [ ] Check HTMX fragments don't include unsanitized user data in HTML attributes

- [ ] Verify `hx-vals`, `hx-headers` don't include raw user input

### Step 5: JavaScript Context

- [ ] Check for inline `<script>` blocks interpolating Django variables

- [ ] Verify `{{ variable|escapejs }}` is used when passing data to JS

- [ ] Check Alpine.js `x-data` attributes for unescaped user data

- [ ] Verify JSON serialization uses `|json_script` filter (auto-escapes)

### Step 6: HTTP Headers

- [ ] Verify `Content-Type: text/html` on HTML responses (not `text/plain` with HTML)

- [ ] Check CSP headers prevent inline script execution (nonce-based)

- [ ] Verify `X-Content-Type-Options: nosniff` is set

### Step 7: Report

- [ ] Categorize by OWASP severity: Critical, High, Medium, Low

- [ ] List affected files with line numbers

- [ ] Provide specific fix for each finding
