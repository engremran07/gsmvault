---
name: dependency-auditor
description: >-
  Audits Python dependencies for vulnerabilities. Use when: outdated packages, CVE scan, pip-audit, dependency security review.
---

# Dependency Auditor

Audits all Python dependencies in `requirements.txt` for known vulnerabilities, outdated versions, and security advisories.

## Scope

- `requirements.txt`
- `.venv/` (installed packages)
- `pyproject.toml` (if dependency config exists)

## Rules

1. `requirements.txt` is the single source of truth for all dependencies
2. Every entry must have version pinning: `>=min,<major_ceiling` format
3. Run `pip-audit` or `safety check` to identify known CVEs
4. Critical/high severity CVEs must be flagged for immediate update
5. Check `pip check` for broken dependency chains
6. Verify type stub packages match their parent package versions
7. No packages with known end-of-life status (e.g., Python 2 only packages)
8. Check for packages with no maintenance (no release in 2+ years) — flag for replacement
9. Verify all packages in `requirements.txt` are actually imported in the codebase
10. Never use `pip freeze > requirements.txt` — curate manually with organized sections

## Procedure

1. Parse `requirements.txt` and list all direct dependencies
2. Run `pip-audit` against installed packages
3. Run `pip check` for dependency conflicts
4. Check `pip list --outdated` for available updates
5. Cross-reference each package against NIST NVD for CVEs
6. Verify each package is actually used in the codebase

## Output

Vulnerability report with package name, installed version, CVE IDs, severity, and recommended version.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
