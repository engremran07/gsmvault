---
paths: ["**"]
---

# Unification Over Creation

When fixing a bug or adding a feature, ALWAYS prefer editing existing files over
creating new ones. This is the core philosophy of this codebase.

## Decision Framework

Ask yourself before creating any file:

1. **Does a file already exist that should contain this?** → Edit it
2. **Is there an existing pattern I should follow?** → Follow it, don't create a parallel one
3. **Am I creating this because the existing code is "messy"?** → Clean the existing code instead
4. **Am I creating a helper that will only be used once?** → Inline it

## MUST Unify

- One `services.py` per app (or `services/` directory) — never `services_v2.py`
- One `models.py` per app — never `models_new.py`
- One admin registration per model — never duplicate `ModelAdmin` classes
- One URL namespace per app — never multiple URL patterns for the same view
- One sanitization chain — `apps.core.sanitizers` is the single source
- One canonical implementation per domain flow in `apps/seo`, `apps/distribution`, and `apps/ads` — extend current models/services instead of adding parallel files

## MUST NOT Create

- Wrapper files that just re-import from another module (except `apps.core.models` re-export shim)
- "Temporary" files with the intent to replace later (fix properly now)
- Alternative implementations to "compare" — pick one, implement it, delete the experiment
- README files in every subdirectory (document in `AGENTS.md` instead)
- Alternate SEO/Distribution/Ads modules like `seo_v2.py`, `distribution_new.py`, `ads_refactor.py`, or duplicate model/service files
- New static files for small one-off adjustments when existing static modules can be cleanly extended

## When Consolidation Is Needed

If you find duplicated code:
1. Identify the canonical location (usually the earliest or most complete version)
2. Move all unique logic to the canonical location
3. Update all imports to point to the canonical location
4. Delete the duplicate
5. Run the quality gate to verify nothing broke

## Python Naming Standard

- Python files must use generic, stable snake_case names consistent with Django conventions.
- Prefer existing canonical names (`models.py`, `services.py`, `tasks.py`) over introducing stylistic variants.
- Do not rename or fork files just to reflect "upgrade" state; upgrades happen in-place.

## Static Split Policy

- Keep static files minimized by default; avoid file proliferation.
- Split only when file size/complexity causes measurable lag, review pain, or unstable ownership.
- When splitting, ensure cohesive naming, remove obsolete code, and preserve existing import/load order guarantees.

## Regression Safety

- Unification must never degrade behavior.
- Complete the quality gate and verify that backend contracts, templates/components, and persisted data flows remain consistent.
