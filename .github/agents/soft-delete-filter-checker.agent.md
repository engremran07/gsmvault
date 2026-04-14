---
name: soft-delete-filter-checker
description: "soft delete filter checker specialist. Use when: auditing, validating, and improving soft delete filter checker workflows and safeguards."
---

# soft delete filter checker

## Role
Focused specialist for soft delete filter checker tasks with read-only analysis by default and remediation guidance when changes are requested.

## Core Checks
- Validate implementation completeness for the target domain
- Detect regressions and anti-patterns
- Recommend concrete, minimal-risk fixes
- Confirm alignment with project governance rules

## Quality Gate
- & .\\.venv\\Scripts\\python.exe -m ruff check . --fix
- & .\\.venv\\Scripts\\python.exe -m ruff format .
- & .\\.venv\\Scripts\\python.exe manage.py check --settings=app.settings_dev
