---
paths: ["apps/*/models.py", "apps/*/services*.py", "apps/*/views.py", "templates/**"]
---

# XSS Prevention

All user-supplied content MUST be sanitized before storage or rendering. The platform uses nh3 (Rust-based) exclusively — bleach is deprecated and MUST NOT be used.

## Sanitization Functions

- **`apps.core.sanitizers.sanitize_html_content()`** — MUST be used for all user-supplied HTML (blog posts, forum replies, comments, wiki headers, page content).
- **`apps.core.sanitizers.sanitize_ad_code()`** — MUST be used for ad network HTML that requires limited tags (iframes, scripts from whitelisted domains).
- **`apps.core.sanitizers.sanitize_plain_text()`** — MUST be used when stripping ALL HTML (usernames, titles, slugs, metadata fields).
- NEVER use `bleach` — it is deprecated and removed from `requirements.txt`. The nh3 library replaces it entirely.
- NEVER write inline sanitization logic — always call the centralized sanitizers.

## Sanitize Before Storage

- Sanitize in the model `save()` method or service layer BEFORE writing to the database.
- NEVER sanitize only at render time — stored XSS is the primary threat.
- Known guard points that MUST sanitize on save:
  - `blog.Post.save()` — body, excerpt
  - `forum.services.create_reply()` / `create_topic()` — content, wiki headers
  - `pages.Page.save()` — body content
  - `comments.Comment.save()` — body
  - `ads` service layer — creative HTML, affiliate descriptions

## Template Output Rules

- Django auto-escapes by default (`{{ value|escape }}`) — do NOT disable this.
- The `|safe` filter is ONLY permitted on content that has ALREADY been sanitized by `sanitize_html_content()` before storage.
- NEVER use `|safe` on raw user input, request parameters, or unsanitized database fields.
- NEVER use `{% autoescape off %}` blocks unless rendering pre-sanitized rich content AND the block is minimal.
- Mark sanitized content clearly in context: prefer variable names like `sanitized_body` or comments indicating the field is pre-sanitized.

## URL Validation

- ALWAYS use `is_safe_url()` before redirecting to any user-supplied URL.
- NEVER construct redirect URLs by string concatenation with user input.
- Validate `next` parameters, `HTTP_REFERER` fallbacks, and any URL stored from user forms.
- Reject URLs with `javascript:`, `data:`, or `vbscript:` schemes.

## JavaScript and Inline Content

- NEVER inject user-supplied data into inline `<script>` blocks — use `data-*` attributes and read them in JS.
- JSON data for Alpine.js `x-data` MUST be escaped with `|escapejs` or serialized through `json_script`.
- NEVER use `innerHTML` with unsanitized content in JS — use `textContent` or DOM APIs.
