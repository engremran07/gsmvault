# /test-admin â€” Run admin app test suite

Execute all tests for the custom admin panel covering all 8 view modules, KPI cards, audit log, and bulk actions.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Run Admin Tests

- [ ] Full suite: `& .\.venv\Scripts\python.exe -m pytest apps/admin/ -v --settings=app.settings_dev`

- [ ] Specific module: `& .\.venv\Scripts\python.exe -m pytest apps/admin/ -v -k "$ARGUMENTS" --settings=app.settings_dev`

- [ ] With coverage: `& .\.venv\Scripts\python.exe -m pytest apps/admin/ -v --cov=apps/admin --cov-report=term-missing`

### Step 2: Verify View Module Coverage

- [ ] `views_auth.py`: login, logout, session management, MFA flows

- [ ] `views_content.py`: blog, pages, comments, tags management

- [ ] `views_distribution.py`: content syndication, social posting admin

- [ ] `views_extended.py`: forum, gamification, bounty, marketplace admin

- [ ] `views_infrastructure.py`: backup, storage, notifications, celery admin

- [ ] `views_security.py`: WAF rules, blocked IPs, crawler rules, security events

- [ ] `views_settings.py`: site settings, consent, SEO config

- [ ] `views_users.py`: user management, profiles, permissions

### Step 3: Verify Component Usage

- [ ] KPI cards use `{% include "components/_admin_kpi_card.html" %}`

- [ ] Search bars use `{% include "components/_admin_search.html" %}`

- [ ] Data tables use `{% include "components/_admin_table.html" %}`

- [ ] Audit log entries: AuditLog, AdminAction, FieldChange creation

- [ ] Bulk actions: multi-select approve/reject/delete operations

- [ ] `_render_admin()` decorator enforces `@login_required` + `is_staff`

### Step 4: Check Results

- [ ] All tests pass (zero failures)

- [ ] Admin views return 403 for non-staff users

- [ ] Coverage above project threshold

- [ ] Run quality gate: `& .\.venv\Scripts\python.exe -m ruff check apps/admin/`
