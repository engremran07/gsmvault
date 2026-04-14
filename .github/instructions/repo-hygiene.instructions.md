---
applyTo: '**/*.py, **/*.md, templates/**/*.html, static/css/**, static/js/**/*.js, **/*.json, **/*.yml, **/*.yaml, .github/workflows/*.yml, .github/workflows/*.yaml'
---

# Repository Hygiene Instructions

## Purpose

Enforce systematic repository cleanliness and zero stale artifact references for all major filetypes that can surface diagnostics in the Problems tab.

## Required Checks Before Completion

1. Real-source diagnostics must be zero for:
- Python (ruff, pyright, pylance)
- Markdown (markdown lint)
- HTML/CSS/SCSS/JS
- YAML and JSON
2. Remove temporary artifacts created during implementation or audit passes.
3. Remove references to any removed temporary file from docs, prompts, workflows, and scripts.
4. Keep workflow files strict-valid YAML with no schema warnings.

## YAML and Workflow Discipline

- Keep indentation consistent and avoid ambiguous scalar syntax.
- Avoid duplicate keys and mixed tab/space indentation.
- Keep workflow steps deterministic and lint-clean.
- If adding temporary workflow debug steps, remove them before completion.

## SCSS and Static Hygiene

- Extend existing canonical SCSS modules before creating new files.
- Remove stale selectors and stale imports when refactoring.
- Ensure no dead references to removed static files remain.

## Artifact Hygiene

- Treat ad-hoc outputs as temporary unless explicitly required by project docs.
- Do not leave stale references to local-only files.
- After task completion, clean transient artifacts and verify no broken references remain.
