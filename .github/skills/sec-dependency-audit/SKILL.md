---
name: sec-dependency-audit
description: "Dependency vulnerability scanning: pip-audit, safety, CVE checks. Use when: auditing Python dependencies, checking for known vulnerabilities."
---

# Dependency Vulnerability Audit

## When to Use

- Auditing Python dependencies for known CVEs
- Running pre-deploy security checks
- Continuous integration security scanning

## Rules

| Tool | Purpose | Command |
|------|---------|---------|
| `pip-audit` | Python advisory DB check | `pip-audit -r requirements.txt` |
| `pip check` | Dependency consistency | `pip check` |
| `pip list --outdated` | Outdated package detection | `pip list --outdated` |
| `safety` | Safety DB vulnerability check | `safety check` |

## Patterns

### pip-audit (Recommended)
```powershell
# Install
& .\.venv\Scripts\pip.exe install pip-audit

# Audit all installed packages
& .\.venv\Scripts\python.exe -m pip_audit

# Audit from requirements file
& .\.venv\Scripts\python.exe -m pip_audit -r requirements.txt

# JSON output for CI
& .\.venv\Scripts\python.exe -m pip_audit --format=json -o audit-report.json
```

### Dependency Consistency Check
```powershell
# Check for broken dependency chains
& .\.venv\Scripts\pip.exe check

# Check transitive deps before removing a package
& .\.venv\Scripts\pip.exe show <package-name>  # check "Required-by:" field
```

### CI Pipeline Integration
```yaml
# GitHub Actions
- name: Audit dependencies
  run: |
    pip install pip-audit
    pip-audit -r requirements.txt --strict
```

### Manual CVE Check Process
```python
# Management command for periodic audit
from django.core.management.base import BaseCommand
import subprocess

class Command(BaseCommand):
    help = "Run dependency security audit"

    def handle(self, *args, **options):
        result = subprocess.run(
            ["pip-audit", "--format=json"],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            self.stderr.write(self.style.ERROR("Vulnerabilities found:"))
            self.stderr.write(result.stdout)
        else:
            self.stdout.write(self.style.SUCCESS("No vulnerabilities found."))
```

### Pre-Deploy Audit Checklist
```markdown
1. `pip check` — no broken dependencies
2. `pip-audit` — no known CVEs
3. `pip list --outdated` — review outdated packages
4. Check `requirements.txt` matches installed packages
5. Review any `# type: ignore` additions for security impact
```

### Pinned Version Strategy
```text
# requirements.txt — pin ranges, not exact
Django>=5.2.9,<5.3
djangorestframework>=3.15.0,<4.0
PyJWT>=2.9.0,<3.0
nh3>=0.2.18,<1.0
```

## Red Flags

- No dependency audit in CI pipeline
- Unpinned dependencies (`Django` without version range)
- Known CVEs in installed packages without remediation plan
- `pip freeze > requirements.txt` instead of curated file
- No `pip check` in quality gate

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
