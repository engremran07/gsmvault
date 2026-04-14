---
paths: ["**"]
---

# Zero-Tolerance Problems Tab Policy

The VS Code Problems tab MUST remain permanently clean across ALL file types.
Any error, warning, or information diagnostic in the Problems tab is a blocking issue.

## Scope — ALL Error Types

This rule covers EVERY diagnostic source that can appear in the Problems tab:

### Python Diagnostics
| Source | Severity | Action |
|--------|----------|--------|
| **Ruff** (E, W, F, I, N, UP, B, C4, SIM, RUF) | Error/Warning | Fix immediately with `ruff check . --fix` then manual fixes |
| **Pyright** (reportMissingImports, reportGeneralTypeIssues, etc.) | Error | Fix type annotations, add stubs, narrow types |
| **Pylance** (type errors, unresolved imports, type mismatches) | Error/Warning | Fix using proper type hints, `TYPE_CHECKING` imports |
| **Django Check** (system check warnings/errors) | All | Fix model meta, URL config, settings issues |

### Frontend Diagnostics
| Source | Severity | Action |
|--------|----------|--------|
| **HTML validation** (unclosed tags, invalid attributes) | Error/Warning | Fix tag structure, use valid HTML5 attributes |
| **CSS/SCSS** (invalid properties, syntax errors) | Error/Warning | Fix syntax, use valid CSS properties |
| **JavaScript** (syntax errors, undefined variables) | Error/Warning | Fix JS syntax, declare variables properly |
| **JSON** (syntax errors, trailing commas) | Error | Fix JSON syntax strictly |
| **YAML** (indentation, syntax) | Error | Fix YAML formatting |

### Documentation Diagnostics
| Source | Severity | Action |
|--------|----------|--------|
| **Markdown lint** (MD001–MD058) | Warning/Info | Fix heading hierarchy, line length, formatting |
| **Spell check** (misspelled words) | Info | Fix typos or add to dictionary |

### Template Diagnostics
| Source | Severity | Action |
|--------|----------|--------|
| **Django template** (unclosed tags, invalid filters) | Error | Fix template tag syntax |
| **Jinja/DTL syntax** (mismatched blocks) | Error | Fix block/endblock pairing |

## Enforcement Rules

1. **Before starting work**: Run `get_errors()` — if ANY real source file errors exist, fix them FIRST
2. **After every file edit**: Check the Problems tab — new errors are your responsibility
3. **Before marking task complete**: Run the full quality gate AND verify Problems tab is clean
4. **Terminal pseudo-files**: Ignore diagnostics from `vscode-terminal:/` URIs — these are VS Code artifacts, not real source errors

## Quality Gate — MANDATORY Sequence

```powershell
# Step 1: Python lint + format
& .\.venv\Scripts\ruff.exe check . --fix
& .\.venv\Scripts\ruff.exe format .

# Step 2: Django system check
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev

# Step 3: Type check (Pyright is authoritative)
& .\.venv\Scripts\python.exe -m pyright apps/

# Step 4: Verify Problems tab
# Use get_errors() tool — must return zero real source file errors
```

## What Counts as "Clean"

- Zero errors from ANY source on ANY real source file
- Zero warnings from ruff, Pyright, or Pylance on Python files
- Zero Django system check issues (including silenced ones — investigate those too)
- `vscode-terminal:/` pseudo-file diagnostics are excluded (VS Code artifacts)

## What Does NOT Count as "Clean"

- "It was already broken before I started" — fix it anyway
- "It's just a warning, not an error" — warnings are errors in this project
- "It's in a file I didn't touch" — if it's in the Problems tab, fix it
- "The type stub is missing" — install the stub or add a scoped `# type: ignore[import-untyped]`

## Forbidden Shortcuts

- **NEVER** add blanket `# type: ignore` — always specify the error code
- **NEVER** add `# noqa` without specifying the rule code
- **NEVER** disable a ruff rule project-wide to silence a warning
- **NEVER** add `# pragma: no cover` to skip coverage on untested code
- **NEVER** suppress Pyright errors with `type: ignore` on lines that should be properly typed
