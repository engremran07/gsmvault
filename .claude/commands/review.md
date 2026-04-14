# /review â€” Code Review

Perform a comprehensive code review of recent changes (or files specified in $ARGUMENTS).

## Review Checklist

### Correctness

- [ ] Logic is correct and matches stated intent

- [ ] Edge cases handled (empty querysets, null values, permission denied)

- [ ] No off-by-one errors in pagination or loop bounds

### Django Best Practices

- [ ] Business logic in `services.py`, not in views

- [ ] No N+1 query patterns (check for lazy FK traversal in loops)

- [ ] `select_related` / `prefetch_related` used where needed

- [ ] `@transaction.atomic` on multi-model writes

- [ ] `select_for_update()` on wallet/credit operations

### Code Quality (AGENTS.md compliance)

- [ ] Full type hints on all public functions

- [ ] `related_name` on all FK/M2M fields

- [ ] `__str__`, `Meta.db_table`, `Meta.ordering` on new models

- [ ] No `fields = "__all__"` in serializers

- [ ] `permission_classes` on every API ViewSet

- [ ] Never bare `# type: ignore` (must have error code)

### Security (OWASP)

- [ ] No raw SQL

- [ ] No secrets or credentials in code

- [ ] User input validated/sanitized before persistence

- [ ] Auth checks in all non-public views

- [ ] CSRF tokens on all forms

### Frontend (if templates changed)

- [ ] `x-cloak` on all Alpine `x-show`/`x-if` elements

- [ ] No `text-white` on accent backgrounds (use `var(--color-accent-text)`)

- [ ] `{% csrf_token %}` in all forms

- [ ] No `{% extends %}` in HTMX fragments

- [ ] Reusable components used (not inline duplicates)

## Output Format

Provide findings grouped by severity:
- **Critical**: Must fix before merge
- **Warning**: Should fix but not blocking
- **Suggestion**: Optional improvement
- **Approved**: Clean with no significant issues
