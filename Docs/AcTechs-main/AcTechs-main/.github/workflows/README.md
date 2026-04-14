# Workflow Guide

## Overview

| Workflow | File | Purpose |
| --- | --- | --- |
| CI | `ci.yml` | Static analysis, Flutter tests, Firestore rules tests, debug APK build, web build, and hygiene gates |
| Weekly audit | `audit.yml` | Scheduled governance and regression checks that look for policy drift |
| Release | `release.yml` | Tag-driven release validation plus APK and web artifacts |
| Deploy web | `deploy-web.yml` | Build and deploy Flutter web to Firebase Hosting |
| Build APK | `build-apk.yml` | Reusable Android build workflow |

## Expectations

- Shell-root routes may use `context.go()`; pushed detail routes may not.
- Web and APK are one release surface: if behavior changes, both must be validated.
- Firestore rule changes are not complete until lint and emulator tests pass.
- Governance continuity files must stay present in the repository root.

## Local equivalent order

1. `flutter analyze --no-pub`
2. `flutter test --coverage`
3. `npm run lint:firestore-rules` from `scripts/`
4. `npm test` from `scripts/`
5. `flutter build web --release --no-wasm-dry-run`
6. `flutter build apk --release --no-tree-shake-icons`
