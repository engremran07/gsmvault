---
name: revenue-reporting-auditor
description: "revenue reporting auditor specialist. Use when: auditing, validating, and improving revenue reporting auditor workflows and safeguards."
---

# revenue reporting auditor

## Role
Focused specialist for revenue reporting auditor tasks with read-only analysis by default and remediation guidance when changes are requested.

## Core Checks
- Validate implementation completeness for the target domain
- Detect regressions and anti-patterns
- Recommend concrete, minimal-risk fixes
- Confirm alignment with project governance rules

## Quality Gate
- & .\\.venv\\Scripts\\python.exe -m ruff check . --fix
- & .\\.venv\\Scripts\\python.exe -m ruff format .
- & .\\.venv\\Scripts\\python.exe manage.py check --settings=app.settings_dev
