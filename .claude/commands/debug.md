# /debug â€” Structured Debugging

Debug the issue described in $ARGUMENTS using a structured hypothesis-driven approach.

## Step 1: Gather Context (ask 3 questions)

Before suggesting anything:
1. What is the exact error message or unexpected behaviour? (paste the full traceback if available)
2. What specific action triggers it? (URL visited, form submitted, task run, etc.)
3. What was the last change made before the issue appeared?

## Step 2: Reproduce

Attempt to reproduce the issue:
- Read the relevant view/service/model code
- Check recent git changes: `git log --oneline -10`
- Run the Django system check: `manage.py check --settings=app.settings_dev`
- Check for relevant migration state: `manage.py showmigrations --settings=app.settings_dev`

## Step 3: Form Hypotheses

List 3-5 specific hypotheses ranked by probability. For each:
- What could cause this exact error/behaviour?
- What evidence supports or refutes this hypothesis?

## Step 4: Test Hypotheses

Systematically test each hypothesis:
- Add targeted debug logging: `import logging; logger = logging.getLogger(__name__); logger.debug("...")`
- Read the specific code paths involved
- Check database state if relevant

## Step 5: Implement Fix

Once root cause confirmed:
1. Write the minimal fix â€” avoid scope creep.
2. Add a regression test that would have caught this bug.
3. Run `/qa` to verify the fix doesn't break anything.

## Common Django Issues Quick-Reference

| Symptom | Likely Cause |
|---------|-------------|
| `RelatedObjectDoesNotExist` | FK with no matching object; check `select_related` |
| `IntegrityError: NOT NULL` | Required field missing in serializer or form |
| `OperationalError: no such table` | Missing migration; run `makemigrations` + `migrate` |
| `ImportError: cannot import` | Circular import or dissolved app referenced |
| CSRF error on POST | Missing `{% csrf_token %}` or JS fetch missing `X-CSRFToken` header |
| Alpine `x-show` flicker | Missing `x-cloak` or conflicting animation class |
| HTMX partial renders full page | Fragment incorrectly uses `{% extends %}` |
| N+1 on queryset loop | Missing `select_related` / `prefetch_related` |
| Type error in Pylance on reverse FK | Django reverse managers need `# type: ignore[attr-defined]` |
