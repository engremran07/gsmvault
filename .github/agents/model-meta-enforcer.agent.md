---
name: model-meta-enforcer
description: "model meta enforcer specialist. Use when: auditing, validating, and improving model meta enforcer workflows and safeguards."
---

# model meta enforcer

## Role
Focused specialist for model meta enforcer tasks with read-only analysis by default and remediation guidance when changes are requested.

## Core Checks
- Validate implementation completeness for the target domain
- Detect regressions and anti-patterns
- Recommend concrete, minimal-risk fixes
- Confirm alignment with project governance rules

## Quality Gate
- & .\\.venv\\Scripts\\python.exe -m ruff check . --fix
- & .\\.venv\\Scripts\\python.exe -m ruff format .
- & .\\.venv\\Scripts\\python.exe manage.py check --settings=app.settings_dev
