---
name: dependency-license-checker
description: >-
  Verifies dependency licenses are compatible. Use when: license compliance, OSS audit, license compatibility check.
---

# Dependency License Checker

Verifies that all Python dependency licenses are compatible with the project's license and comply with organizational policies.

## Scope

- `requirements.txt`
- `.venv/` (installed package metadata)

## Rules

1. All dependencies must have an identifiable license — flag packages with no license metadata
2. GPL-licensed packages must be flagged — they impose copyleft obligations on the entire project
3. AGPL-licensed packages are FORBIDDEN for proprietary/SaaS projects
4. MIT, BSD, Apache 2.0, ISC, and PSF licenses are safe for commercial use
5. LGPL packages are acceptable if used as libraries (not modified)
6. Dual-licensed packages must document which license applies
7. Packages with "Custom" or unclear licenses require legal review
8. Check transitive dependencies — a MIT package pulling in a GPL dep creates obligation
9. License metadata must match actual license files in the package
10. Maintain a license inventory for compliance documentation

## Procedure

1. Extract license metadata for every installed package via `pip show`
2. Classify each license as permissive, copyleft, or restricted
3. Flag incompatible licenses for review
4. Check transitive dependency licenses
5. Generate a license inventory spreadsheet
6. Identify packages requiring legal review

## Output

License compliance report with package name, license type, compatibility status, and action required.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
