---
name: admin-panel
description: "Admin panel architecture and templates. Use when: creating admin views, admin templates, sidebar navigation, _render_admin pattern, CRUD pages, admin dashboard."
---

# Admin Panel Skill

## Architecture

All admin views live in `apps/admin/views_*.py` — 8 modules:

| Module | Responsibility |
|---|---|
| `views_auth.py` | Login, logout, 2FA, session management |
| `views_content.py` | Blog, pages, comments, tags, firmware moderation |
| `views_distribution.py` | Content syndication, social sharing |
| `views_extended.py` | Marketplace, bounty, gamification, referral |
| `views_infrastructure.py` | Storage, backups, Celery tasks, system health |
| `views_security.py` | WAF rules, blocked IPs, rate limits, crawlers, security events |
| `views_settings.py` | Site settings, app registry, feature flags |
| `views_users.py` | User management, profiles, roles, permissions |

Shared utilities in `views_shared.py` — all view modules do `from .views_shared import *`.

URLs in `apps/admin/urls.py` with namespace `admin_suite`.

---

## _render_admin Pattern

Every admin view calls the shared render helper:

```python
from .views_shared import _render_admin

def my_admin_view(request):
    context = {"items": MyModel.objects.all()}
    return _render_admin(
        request,
        "admin_suite/my_page.html",
        context,
        nav_active="my_section",
        breadcrumb=[
            {"label": "Dashboard", "url": "/admin-suite/"},
            {"label": "My Page"},
        ],
        subtitle="Optional page subtitle",
    )
```

`_render_admin` injects into context:
- `nav_active` — string matching sidebar nav item for active state
- `breadcrumb` — list of `{"label": str, "url": str?}` dicts
- `subtitle` — optional text below page title
- Plus any view-specific context passed in

---

## Template Hierarchy

```
templates/base/_base.html           ← Root HTML document
  └─ templates/layouts/admin.html   ← Admin layout (sidebar + content area)
      └─ templates/admin_suite/<page>.html  ← Individual admin pages
```

Includes used by admin layout:
- `admin_suite/_sidebar.html` — Navigation sidebar
- `admin_suite/_page_header.html` — Breadcrumb + title + subtitle

---

## Layout Blocks

Admin pages extend `layouts/admin.html` and fill these blocks:

```html
{% extends "layouts/admin.html" %}

{% block page_header %}
  {% include "admin_suite/_page_header.html" %}
{% endblock %}

{% block page_content %}
  <!-- Main page content here -->
{% endblock %}
```

---

## Sidebar Navigation

13 navigation sections in `admin_suite/_sidebar.html`:

| Section | nav_active values | Views module |
|---|---|---|
| Dashboard | `dashboard` | views.py |
| Pending | `pending_approval` | views_content.py |
| Security | `security_overview`, `waf_rules`, `blocked_ips`, `rate_limits`, `crawlers`, `security_events`, `csp_reports` | views_security.py |
| Users | `users`, `user_detail`, `profiles`, `roles` | views_users.py |
| Content & CMS | `blog`, `pages`, `comments`, `tags` | views_content.py |
| SEO | `seo` | views_content.py |
| Firmwares | `firmwares`, `devices`, `scraper`, `gsmarena` | views_content.py |
| Ads & Marketing | `ads`, `affiliates` | views_content.py |
| Distribution | `distribution` | views_distribution.py |
| Storage | `storage`, `backups` | views_infrastructure.py |
| AI | `ai_providers`, `analytics`, `behavior` | views_extended.py |
| Credits | `wallet`, `shop`, `marketplace`, `bounty`, `referral`, `gamification` | views_extended.py |
| Audit Log | `audit_log` | views_content.py |

Active state: sidebar item gets `active` class when its `nav_active` value matches the one injected by `_render_admin`.

---

## Standard Page Pattern

A typical admin page follows this structure:

```html
{% extends "layouts/admin.html" %}
{% load humanize %}

{% block page_header %}
  {% include "admin_suite/_page_header.html" %}
{% endblock %}

{% block page_content %}
<!-- Stat Cards — ALWAYS use the reusable component -->
<div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
  {% include "components/_admin_kpi_card.html" with label="Total Items" value=total_count %}
  {% include "components/_admin_kpi_card.html" with label="Active" value=active_count icon="check-circle" %}
  {% include "components/_admin_kpi_card.html" with label="Pending" value=pending_count icon="clock" %}
  {% include "components/_admin_kpi_card.html" with label="Failed" value=failed_count icon="alert-triangle" %}
</div>

<!-- Data Table — ALWAYS use the reusable component -->
{% include "components/_admin_table.html" with items=items columns=columns %}

<!-- Pagination -->
{% include "components/_pagination.html" with page_obj=page_obj %}
{% endblock %}
```

---

## HTMX Fragments

Admin pages can serve HTMX partial updates via fragments in `templates/admin_suite/fragments/`:

```python
def my_admin_view(request):
    items = MyModel.objects.all()
    if request.headers.get("HX-Request"):
        return render(request, "admin_suite/fragments/my_table.html", {"items": items})
    return _render_admin(request, "admin_suite/my_page.html", {"items": items}, ...)
```

Fragment templates render only the updated portion (table body, card, etc.) — no layout wrapping.

---

## 52 Admin Templates

Complete template inventory in `templates/admin_suite/`:

### Dashboard
- `dashboard.html` → `nav_active="dashboard"`

### Security
- `security_overview.html` → `nav_active="security_overview"`
- `waf_rules.html` → `nav_active="waf_rules"`
- `waf_rule_detail.html` → `nav_active="waf_rules"`
- `blocked_ips.html` → `nav_active="blocked_ips"`
- `rate_limits.html` → `nav_active="rate_limits"`
- `rate_limit_detail.html` → `nav_active="rate_limits"`
- `crawlers.html` → `nav_active="crawlers"`
- `crawler_detail.html` → `nav_active="crawlers"`
- `security_events.html` → `nav_active="security_events"`
- `security_event_detail.html` → `nav_active="security_events"`
- `csp_reports.html` → `nav_active="csp_reports"`

### Users
- `users.html` → `nav_active="users"`
- `user_detail.html` → `nav_active="users"`
- `user_create.html` → `nav_active="users"`
- `user_edit.html` → `nav_active="users"`

### Content
- `blog_posts.html` → `nav_active="blog"`
- `blog_post_detail.html` → `nav_active="blog"`
- `pages.html` → `nav_active="pages"`
- `page_detail.html` → `nav_active="pages"`
- `comments.html` → `nav_active="comments"`
- `tags.html` → `nav_active="tags"`
- `firmwares.html` → `nav_active="firmwares"`
- `firmware_detail.html` → `nav_active="firmwares"`
- `devices.html` → `nav_active="devices"`
- `device_detail.html` → `nav_active="devices"`

### Infrastructure
- `storage.html` → `nav_active="storage"`
- `backups.html` → `nav_active="backups"`
- `celery_tasks.html` → `nav_active="celery"`
- `system_health.html` → `nav_active="system_health"`

### AI & Analytics
- `ai_providers.html` → `nav_active="ai_providers"`
- `analytics_overview.html` → `nav_active="analytics"`
- `behavior_insights.html` → `nav_active="behavior"`

### Config
- `site_settings.html` → `nav_active="site_settings"`
- `app_registry.html` → `nav_active="app_registry"`
- `feature_flags.html` → `nav_active="feature_flags"`

### Distribution
- `distribution_overview.html` → `nav_active="distribution"`
- `syndication.html` → `nav_active="syndication"`

### Extended
- `marketplace.html` → `nav_active="marketplace"`
- `bounty.html` → `nav_active="bounty"`
- `gamification.html` → `nav_active="gamification"`
- `referral.html` → `nav_active="referral"`
- `shop.html` → `nav_active="shop"`
- `wallet.html` → `nav_active="wallet"`

### Shared Partials
- `_sidebar.html`
- `_page_header.html`
- `_stat_card.html`
- `_data_table.html`
- `_action_bar.html`

### Fragments (HTMX)
- `fragments/` — partial update templates matching parent pages

---

## Common Mistakes

1. **Never inline stat cards** — always use `{% include "components/_admin_kpi_card.html" %}`. See `admin-components` skill.
2. **Never inline tables** — always use `{% include "components/_admin_table.html" %}`. Manual `<table>` HTML is forbidden.
3. **Never call `render()` directly** — always use `_render_admin()` from `views_shared.py`.
4. **`--color-accent-text` is WHITE in dark/light but BLACK in contrast** — always use the CSS token on accent backgrounds, never hardcode `text-white`.
5. **Admin views MUST check `is_staff`** — use `@staff_member_required`, never just `@login_required`.
6. **Every `<form method="post">` needs `{% csrf_token %}`** — no exceptions.
7. **HTMX requests in admin need CSRF** — set `hx-headers='{"X-CSRFToken": "{{ csrf_token }}"}'` on `<body>` tag.
