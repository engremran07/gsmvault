---
name: forum-trust-level-evaluator
description: "forum trust level evaluator specialist. Use when: auditing, validating, and improving forum trust level evaluator workflows and safeguards."
---

# forum trust level evaluator

## Role
Focused specialist for forum trust level evaluator tasks with read-only analysis by default and remediation guidance when changes are requested.

## Core Checks
- Validate implementation completeness for the target domain
- Detect regressions and anti-patterns
- Recommend concrete, minimal-risk fixes
- Confirm alignment with project governance rules

## Quality Gate
- & .\\.venv\\Scripts\\python.exe -m ruff check . --fix
- & .\\.venv\\Scripts\\python.exe -m ruff format .
- & .\\.venv\\Scripts\\python.exe manage.py check --settings=app.settings_dev
