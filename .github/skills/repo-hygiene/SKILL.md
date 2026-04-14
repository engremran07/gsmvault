---
name: repo-hygiene
description: "Repository cleanliness and artifact lifecycle control. Use when: cleaning temporary files, preventing stale references, validating YAML/Markdown/HTML/CSS/JS/Python diagnostics, and enforcing zero-residue task closure."
---

# Repo Hygiene

## When to Use

- Running broad audits that produce temporary outputs
- Completing tasks that touch many files and diagnostics sources
- Cleaning Problems tab issues beyond Python (YAML, Markdown, HTML/CSS/JS)
- Finalizing governance packs and workflow references

## Procedure

1. Identify all diagnostics in real source files and resolve them.
2. Enumerate temporary artifacts created during the task.
3. Remove temporary artifacts not required as canonical records.
4. Remove stale references to removed artifacts across:
- docs
- prompts
- agent/skill/instruction files
- workflows
- scripts
5. Validate no broken references remain.

## Red Flags

- YAML workflow warnings ignored as non-blocking
- Markdown lint warnings left unresolved
- Temporary output files committed without intent
- References to deleted files remaining in prompts or governance docs
- "It is only local" used as justification for stale residue

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

Additional hygiene checks:

```powershell
# List potential temporary residues
Get-ChildItem output -Recurse -File | Select-Object FullName

# Check for stale references to common temp markers
Get-ChildItem -Recurse -File | Select-String -Pattern 'tmp|temp|artifact|draft|scratch' | Select-Object -First 200
```
