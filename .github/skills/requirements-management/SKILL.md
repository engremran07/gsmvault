---
name: requirements-management
description: "Intelligent requirements.txt management. Use when: adding/removing Python packages, installing dependencies, pip install, removing imports, adding new imports, refactoring apps, dissolving apps, dependency audit, requirements drift, deprecated packages."
---

# Requirements Management

## When to Use

- **Adding a package**: Any `pip install <pkg>` or new `import <pkg>` in code
- **Removing a package**: Deleting an app, removing an import, dissolving an app
- **Refactoring**: Changing which packages an app uses
- **Dependency audit**: Periodic check for drift, deprecated, or missing packages
- **Quality gate**: As part of the extended quality gate checks

## Golden Rule

**`requirements.txt` is the single source of truth for all Python dependencies.** It must always reflect exactly what the project needs — nothing missing, nothing extra, nothing deprecated.

## requirements.txt Structure

The file uses sectioned comments for organization. Always maintain this structure:

```text
# =============================================================================
# Firmware Platform - Python Dependencies
# =============================================================================
# Target: Python 3.x | Django 5.x
# Last updated: <date>
# =============================================================================

# Core Framework
# API & Async
# Security & Auth
# Database & Data
# Content & Media
# Scraping & Data Ingestion
# Cloud & Storage
# Utilities
# Testing & Quality (dev dependencies)
# Code Quality (dev dependencies)
# Type Stubs (dev dependencies)
```

## Verification Commands

```powershell
# Step 1: Check for broken dependency chains
& .\.venv\Scripts\pip.exe check

# Step 2: List top-level packages (not required by others)
& .\.venv\Scripts\pip.exe list --not-required --format=columns

# Step 3: Show what a specific package depends on
& .\.venv\Scripts\pip.exe show <package-name>

# Step 4: Find outdated packages
& .\.venv\Scripts\pip.exe list --outdated --format=columns

# Step 5: Verify a package is installed
& .\.venv\Scripts\pip.exe show <package-name>

# Step 6: Check what depends on a package (before removing)
& .\.venv\Scripts\pip.exe show <package-name>  # check "Required-by:" field
```

## Rules — MANDATORY

### Rule 1: Every Direct Import = Listed in requirements.txt

If any `.py` file in the project does `import <pkg>` or `from <pkg> import ...` where `<pkg>` is a third-party package (not stdlib, not a local app), that package MUST be in `requirements.txt`.

**How to check:**

```powershell
# Search for imports of a specific package
grep -r "import <pkg>" apps/ app/ --include="*.py"
grep -r "from <pkg>" apps/ app/ --include="*.py"
```

### Rule 2: Every requirements.txt Entry = Actually Used

If a package is listed in `requirements.txt`, it must be either:
1. **Directly imported** in at least one `.py` file, OR
2. **A Django app** listed in `INSTALLED_APPS` (e.g., `django-allauth` → `allauth`), OR
3. **A CLI tool** used in scripts/CI (e.g., `ruff`, `mypy`, `bandit`, `pytest`), OR
4. **A runtime dependency** needed by Django/Celery/Gunicorn even if not directly imported

If none of the above apply, the package is extra and must be removed.

### Rule 3: Never Remove a Transitive Dependency Without Checking

Before removing ANY package, always check if it's a child dependency:

```powershell
& .\.venv\Scripts\pip.exe show <package-name>
# Check the "Required-by:" field
# If non-empty, another package depends on it — DO NOT remove from requirements.txt
# unless you're also removing the parent package
```

**Critical:** Some packages are both direct dependencies AND transitive:
- `requests` — used directly in code AND pulled in by other packages
- `Pillow` — used directly AND pulled in by other packages
- In these cases, KEEP them in requirements.txt (direct usage takes priority)

### Rule 4: Pin Ranges, Not Exact Versions

Use minimum version with upper bound to prevent breaking changes:

```text
# CORRECT — minimum version with major version ceiling
Django>=5.2.9,<5.3
celery>=5.4.0

# WRONG — exact pin (blocks security patches)
Django==5.2.9

# WRONG — no minimum (allows ancient broken versions)
Django
```

### Rule 5: Update the Header

When modifying `requirements.txt`, always update the header comment:

```text
# Target: Python 3.x.x | Django 5.x.x
# Last updated: <current date>
```

### Rule 6: Separate Dev Dependencies

Dev-only packages (testing, linting, type stubs) go in clearly labeled sections at the bottom:

```text
# Testing & Quality (dev dependencies)
# Code Quality (dev dependencies)
# Type Stubs (dev dependencies)
```

### Rule 7: Type Stubs in requirements.txt

Type stubs (`django-stubs`, `djangorestframework-stubs`, `types-requests`, etc.) MUST be listed in `requirements.txt` under the "Type Stubs" section — not installed via a separate `pip install` command in documentation. This ensures reproducible environments.

## When Adding a New Package

1. **Install it**: `pip install <package>`
2. **Add to requirements.txt**: In the correct section, with version range
3. **Verify**: `pip check` passes with no broken requirements
4. **Check for new transitive deps**: If the package pulls in something you also use directly, consider listing that too

## When Removing a Package

1. **Search the codebase**: Ensure no `.py` file imports it
   ```powershell
   # Search for all import patterns
   grep -r "import <pkg>" apps/ app/ scripts/ --include="*.py"
   grep -r "from <pkg>" apps/ app/ scripts/ --include="*.py"
   ```
2. **Check INSTALLED_APPS**: Ensure no Django app reference uses it
3. **Check transitive dependents**: `pip show <pkg>` → "Required-by:" must be empty (or you're removing the parent too)
4. **Check if it's a child dep of something staying**: `pip show <parent-pkg>` → "Requires:" — if `<pkg>` is listed and the parent stays, do NOT add `<pkg>` to requirements.txt (let pip resolve it), but also do NOT uninstall it
5. **Remove from requirements.txt**
6. **Uninstall**: `pip uninstall <pkg>` (only if not required by other packages)
7. **Verify**: `pip check` passes

## Dependency Audit Checklist

Run this whenever performing a dependency review or when the quality gate skill triggers it:

- [ ] `pip check` reports "No broken requirements found"
- [ ] Every package in `requirements.txt` is actually installed (`pip show <pkg>` succeeds)
- [ ] Every directly imported third-party package is in `requirements.txt`
- [ ] No package in `requirements.txt` is unused (not imported, not in INSTALLED_APPS, not a CLI tool)
- [ ] No deprecated packages — check PyPI for maintenance status
- [ ] Version ranges use `>=min,<major_ceiling` pattern
- [ ] Header date is current
- [ ] Sections are properly organized
- [ ] Type stubs are in requirements.txt (not just in documentation install commands)
- [ ] `pip list --outdated` reviewed for security-relevant updates

## Common Package → Import Name Mapping

Some packages have different pip names vs import names:

| pip name | import name | Notes |
| --- | --- | --- |
| `django-allauth` | `allauth` | INSTALLED_APPS: `allauth`, `allauth.account`, etc. |
| `django-countries` | `django_countries` | |
| `django-import-export` | `import_export` | |
| `django-solo` | `solo` | |
| `django-redis` | `django_redis` | |
| `djangorestframework` | `rest_framework` | INSTALLED_APPS: `rest_framework` |
| `Pillow` | `PIL` | |
| `psycopg[binary]` | `psycopg` | |
| `python-dotenv` | `dotenv` | |
| `factory-boy` | `factory` | |
| `google-api-python-client` | `googleapiclient` | |
| `beautifulsoup4` | `bs4` | Transitive dep of scrapling/markdownify |
| `PyJWT` | `jwt` | |
| `nh3` | `nh3` | |
| `scrapling` | `scrapling` | |
| `markdownify` | `markdownify` | |
| `celery` | `celery` | |

## Anti-Patterns — NEVER Do These

1. **Never `pip install` without updating requirements.txt** — the install is ephemeral, the file is permanent
2. **Never remove a package without checking `Required-by:`** — you'll break the dependency chain
3. **Never have packages in requirements.txt that aren't installed** — indicates drift
4. **Never duplicate a package** — list each package exactly once
5. **Never use `pip freeze > requirements.txt`** — it dumps ALL transitive deps, making the file unmaintainable. Curate manually.
6. **Never leave type stubs only in documentation** — they must be in requirements.txt for reproducibility
