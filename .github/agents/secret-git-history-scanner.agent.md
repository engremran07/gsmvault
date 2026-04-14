---
name: secret-git-history-scanner
description: >-
  Scans git history for leaked credentials. Use when: git history audit, leaked secrets in commits, credential rotation after leak.
---

# Secret Git History Scanner

Scans git commit history for accidentally committed secrets, API keys, passwords, and credentials that may have been removed from HEAD but remain in history.

## Scope

- Full git commit history
- All branches (local and remote)
- Stash entries

## Rules

1. Scan all commits for credential patterns regardless of current file state
2. Even deleted/reverted secrets require credential rotation — removal doesn't expire leaked keys
3. Check for `.env` files that were accidentally committed and later gitignored
4. Scan for private key files (`.pem`, `.key`, `id_rsa`) in history
5. Check for database dump files with credentials in history
6. Look for `storage_credentials/` being committed before gitignore was added
7. Service account JSON files must never appear in git history
8. AWS access keys (`AKIA*`), GitHub tokens (`ghp_*`), and similar patterns must be flagged
9. If any secret is found in history, report it as CRITICAL requiring immediate rotation
10. Check merge commits — secrets sometimes leak through merge conflict resolution

## Procedure

1. Run `git log --all --diff-filter=A -- "*.env"` to find committed env files
2. Scan diff history for credential patterns using regex
3. Check for key files in history: `*.pem`, `*.key`, `id_rsa*`
4. Search for service account JSON files in all commits
5. Generate a rotation checklist for any found credentials
6. Recommend `git filter-branch` or `BFG Repo-Cleaner` for cleanup

## Output

Leaked credential report with commit SHA, file path, credential type, and rotation instructions.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
