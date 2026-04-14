---
name: input-validation-auditor
description: >-
  Audits form and API input validation completeness. Use when: input validation audit, form validation, serializer validation, missing validators.
---

# Input Validation Auditor

Audits all form and API input validation for completeness, ensuring every user input is properly validated before processing.

## Scope

- `apps/*/forms.py`
- `apps/*/api.py` (DRF serializers)
- `apps/*/views.py` (request data handling)
- `apps/*/services.py` (input at service boundary)

## Rules

1. Every Django form must validate all fields — no form field without validators or clean methods
2. DRF serializers must use field-level validators for business rules
3. User-supplied HTML content MUST be sanitized with `apps.core.sanitizers.sanitize_html_content()`
4. Never trust `request.GET` or `request.POST` data without validation
5. Integer inputs must be range-checked — never pass unchecked integers to database queries
6. String inputs must have `max_length` enforced at both form and model level
7. Email fields must use `EmailField` — never accept emails as `CharField`
8. URL fields must use `URLField` with scheme validation
9. Choice fields must validate against allowed choices — never accept arbitrary values
10. Nested/complex inputs (JSON payloads) must be validated with serializers, not parsed manually

## Procedure

1. Enumerate all forms and check field validators
2. Enumerate all serializers and check field configuration
3. Check views for raw `request.POST`/`request.GET` access without form validation
4. Verify service functions validate inputs at boundaries
5. Check for sanitization of HTML content inputs
6. Identify fields accepting user input without any validation

## Output

Input validation coverage report with form/serializer name, fields, validators present, and gaps.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
