# /dependency-audit â€” Audit requirements.txt integrity

Audit Python dependencies: unused packages, missing packages, outdated versions, security vulnerabilities, and dependency chain integrity.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Dependency Chain Integrity

- [ ] Run `& .\.venv\Scripts\pip.exe check` â€” verify no broken chains

- [ ] Report any packages with unmet dependencies

- [ ] Verify all transitive dependencies are satisfied

### Step 2: Unused Package Detection

- [ ] For each package in `requirements.txt`, search codebase for imports

- [ ] Check `INSTALLED_APPS` in settings for app-installed packages

- [ ] Check CLI tool usage (ruff, pytest, celery, etc.)

- [ ] Before flagging as unused, check `Required-by:` via `pip show <pkg>`

- [ ] List confirmed unused packages for removal

### Step 3: Missing Package Detection

- [ ] Grep all `.py` files for third-party imports

- [ ] Cross-reference against `requirements.txt` entries

- [ ] Flag any imported package not listed in requirements

- [ ] Include type stubs (`django-stubs`, `types-*`, etc.)

### Step 4: Outdated Versions

- [ ] Run `& .\.venv\Scripts\pip.exe list --outdated --format=columns`

- [ ] Categorize: major updates (breaking), minor (features), patch (fixes)

- [ ] Flag packages more than 1 major version behind

- [ ] Check Django compatibility for major updates

### Step 5: Security Vulnerability Check

- [ ] Run `& .\.venv\Scripts\pip.exe audit` or `& .\.venv\Scripts\python.exe -m pip_audit` if available

- [ ] Check critical packages: Django, DRF, Celery, PyJWT, Pillow

- [ ] Flag any packages with known CVEs

- [ ] Provide upgrade paths for vulnerable packages

### Step 6: Version Pinning

- [ ] Verify all packages use version ranges (`>=min,<ceiling`), not bare names

- [ ] Check for overly loose pins that could pull breaking versions

- [ ] Verify no `==` exact pins unless justified (reproducibility vs. security updates)

### Step 7: Report

- [ ] Summary table: Package | Status | Current | Latest | Action

- [ ] List removable packages with confidence level

- [ ] List packages needing urgent security updates
