---
description: "Use when: user asks to build, deploy, release, sync web and APK, or when user-visible Flutter changes must ship consistently across Hosting and Android."
applyTo: "lib/**,web/**,android/**,firebase.json,firestore.rules,firestore.indexes.json,pubspec.yaml,README.md,.github/workflows/**"
---

# Release Surface Sync Instruction

Treat web and APK as one release surface.

- If user-visible behavior, branding, About content, navigation, auth flow, dashboards, localization, or reports changed, do not assume prior build artifacts are still valid.
- Before any release build, confirm pubspec version/build matches the intended release.
- Never claim Hosting and APK are in sync unless both artifacts came from the same current source tree.

Required order when user asks for release or deploy:

0. **Bump pubspec.yaml version** — increment `versionName` and `versionCode` (the `+N` integer) BEFORE any build. The versionCode must always increase. Never build a release with the same versionCode as a previously installed APK.
1. Run `flutter analyze` and any task-specific tests first.
2. Check `git status --short` so the release surface is explicit.
3. **⛔ BLOCKING — Firestore rules deploy**: If `firestore.rules` was modified in this session, you MUST run `firebase deploy --only firestore:rules --project actechs-d415e` before building or installing the APK. An APK that depends on new Firestore rules but runs against old deployed rules WILL fail at runtime with `PERMISSION_DENIED`. This step is non-optional and cannot be skipped.
4. **⛔ BLOCKING — Firestore indexes deploy**: If `firestore.indexes.json` was modified in this session, you MUST run `firebase deploy --only firestore:indexes --project actechs-d415e`. Missing indexes cause silent query failures: queries return empty results rather than errors.
5. Build web when the request affects Firebase Hosting.
6. Deploy Hosting when web output is part of the request.
7. Build release APK when Android delivery is part of the request.
8. **APK install sequence** — uninstall first, then install, to confirm the new versionCode is accepted:
   ```
   $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
   & "$env:ANDROID_HOME\platform-tools\adb.exe" -s <deviceId> uninstall com.actechs.pk
   & "$env:ANDROID_HOME\platform-tools\adb.exe" -s <deviceId> install d:\AcTechs\build\app\outputs\flutter-apk\app-release.apk
   ```
   If uninstall fails (app not installed), proceed with install anyway. Never use `install -r` on a release — it silently accepts a downgrade.
9. Commit or push only after validation and all build/deploy steps succeed.

**Firestore alignment checklist — verify before every APK install:**
| Changed file | Required deploy command |
|---|---|
| `firestore.rules` | `firebase deploy --only firestore:rules --project actechs-d415e` |
| `firestore.indexes.json` | `firebase deploy --only firestore:indexes --project actechs-d415e` |
| Both | `firebase deploy --only firestore --project actechs-d415e` |

**The APK and Firestore must always be deployed from the same source tree.** If rules or indexes changed but were not deployed, the APK is not safe to install — it will silently misbehave.

Strict quality gates (must pass with zero warnings):

- **BLOCKING**: `flutter analyze` exit code must be 0 AND output must contain "No issues found!" before any build or deploy step. Exit code 1 even with only info-level messages is a hard stop.
- Use `get_errors` on every recently modified file BEFORE running `flutter analyze` to catch Problems-tab issues that the IDE surfaces but the CLI may have missed in a previous run.
- Treat warnings (including `info`) as failures for release readiness (rules, lint, analyzer, tests, deploy checks).
- Run `npm run lint:firestore-rules` in `scripts/` before rules tests or rules deploy.
- Run Firestore rules emulator tests and confirm there are no expression-limit evaluator messages in the run logs.
- If any gate produces warnings or expression-limit noise, perform a micro-pass and re-run gates until clean before deploy.

Release verification rules:

- Confirm the displayed app version and build in Settings/About match the built source.
- If web looks older than APK, inspect Hosting cache behavior and the service worker before assuming source drift.
- Do not treat generated build outputs as authoritative if source, localization, routing, or Firebase config changed afterward.

Pre-commit technical debt gate (run before every commit):

1. **Dead code check**: Search for any new provider defined in this PR and verify at least one `ref.watch`/`ref.read`/`ref.listen` call site exists outside its definition file.
2. **Hardcoded string check**: Run `grep -r "\.collection('\|\.doc('" lib/` and confirm zero literal strings — all must use `AppConstants.*`.
3. **Unused import check**: `flutter analyze` must be clean — "No issues found!" blocks any commit with unused imports.
4. **Dependency audit**: If `pubspec.yaml` was modified to add a dependency, confirm at least one `import 'package:package_name'` exists in `lib/`.
5. **Widget orphan check**: If a new widget class was added to `lib/core/widgets/`, confirm it is instantiated in at least one presentation file.

