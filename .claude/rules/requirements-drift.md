---
paths: ["requirements.txt"]
---

# Requirements Drift Prevention

Rules for managing `requirements.txt` — the single source of truth for all Python dependencies.

## Addition Rules

- Every `pip install` MUST be followed by adding the package to `requirements.txt`.
- Pin version ranges: `>=min,<major_ceiling` (e.g., `Django>=5.2.9,<5.3`).
- NEVER use bare package names without versions — every entry MUST have a version specifier.
- Type stubs go in `requirements.txt` alongside runtime packages: `django-stubs`, `djangorestframework-stubs`, `types-requests`.
- Add packages in the correct section (organized by purpose) — never append blindly at the bottom.

## Removal Rules

- Before removing a package: search the entire codebase for imports (`grep_search`).
- Before removing a package: run `pip show <package>` and check `Required-by:` field.
- If another installed package depends on it, do NOT remove — it is a transitive dependency.
- After removing: uninstall with `pip uninstall` and run `pip check` to verify no broken chains.
- When dissolving an app: audit all imports from that app and remove packages no longer used by any remaining app.

## Verification

- Run `pip check` after any change to `requirements.txt` — must report no broken dependencies.
- Every entry in `requirements.txt` MUST be actually used: imported in code, listed in `INSTALLED_APPS`, or used as a CLI tool.
- Periodically run `pip list --outdated` to identify packages needing security updates.
- NEVER use `pip freeze > requirements.txt` — this dumps transitive deps and loses organization.

## Dependency Hygiene

- Prefer well-maintained packages with active security response teams.
- Check CVE databases before adding new dependencies.
- Avoid packages that pull in heavy transitive dependency trees for minor functionality.
- When two packages provide the same functionality, prefer the one already in `requirements.txt`.
- Document why non-obvious packages are included with inline comments.
