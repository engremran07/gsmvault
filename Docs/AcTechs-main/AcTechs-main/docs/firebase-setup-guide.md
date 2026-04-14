# Firebase Setup Guide — AC Techs

This guide reflects the current AC Techs application, including shared-install aggregation, approval settings, company branding, and the Firestore rules/index model used by the app.

## Project Reference

- Firebase project: `actechs-d415e`
- Console: `https://console.firebase.google.com/project/actechs-d415e/overview`
- Android package: `com.actechs.pk`

Main Firebase-backed capabilities:

- Email/password authentication
- Firestore for jobs, expenses, earnings, companies, users, settings, and shared-install aggregates
- App Check support in app dependencies

## Collections Used By The App

The current app relies on these top-level collections and documents:

- `users/{uid}`
- `jobs/{jobId}`
- `expenses/{expenseId}`
- `earnings/{earningId}`
- `companies/{companyId}`
- `app_settings/approval_config`
- `shared_install_aggregates/{aggregateId}`

The `shared_install_aggregates` collection is required for the secure shared-install workflow. Do not remove it from rules or deployments.

## Recommended Setup Order

1. Create or verify the Firebase project.
2. Register Android and Web apps.
3. Enable Email/Password auth.
4. Create Firestore in production mode.
5. Generate or refresh FlutterFire config.
6. Deploy Firestore rules and indexes from the repository.
7. Create the first admin user in Auth and Firestore.
8. Create technician records and at least one company.
9. Verify login, approvals config, and shared-install submission.

## 1. Register The Android App

In Firebase Console:

1. Open project settings.
2. Add an Android app.
3. Use package name `com.actechs.pk`.
4. Download `google-services.json`.
5. Place it at `android/app/google-services.json`.

If the file already exists in the repo workspace for local development, verify it belongs to `actechs-d415e` before replacing it.

## 2. Register The Web App

1. Add a Web app from the same Firebase project settings page.
2. Keep the app under the same Firebase project.
3. Use FlutterFire CLI or the generated config already present in the workspace to keep `firebase_options.dart` aligned.

## 3. Enable Authentication

The app currently uses Email/Password sign-in.

In Firebase Console:

1. Open Authentication.
2. Enable `Email/Password`.
3. Leave passwordless email-link auth disabled unless the app is explicitly changed to support it.

## 4. Create Firestore

1. Open Firestore Database.
2. Create the database in production mode.
3. Choose the region that best fits your deployment and latency requirements.

The app is written against production-style rules. Avoid test-mode rules even during setup if you want behavior to match local development.

## 5. Configure FlutterFire

If you need to regenerate Firebase platform config:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=actechs-d415e
```

That should refresh `firebase_options.dart` and platform-specific Firebase wiring.

## 6. Deploy Firestore Rules And Indexes

Always deploy from the repository files instead of manually pasting rules.

### Deploy Rules Only

```bash
firebase deploy --only firestore:rules --project actechs-d415e
```

### Deploy Rules And Indexes

```bash
firebase deploy --only firestore --project actechs-d415e
```

Current rule expectations include:

- technicians can read only their own jobs
- admins can read and review all jobs
- shared installs use `shared_install_aggregates` for invoice-level reservation tracking
- company and app settings writes are admin-only
- approval behavior depends on `app_settings/approval_config`

## 7. Required Indexes

The project already tracks indexes in `firestore.indexes.json`. At minimum, job queries need indexes compatible with:

- `techId + submittedAt`
- `techId + date`
- `status + submittedAt`
- `status + date`

If Firestore prompts for additional indexes during testing, create them and then export the updated index definition back into the repository.

## 8. Create The First Admin

Create the admin in two places:

### In Firebase Authentication

1. Add a user.
2. Choose an admin email.
3. Set a strong password.
4. Copy the created UID.

### In Firestore

Create `users/{uid}` with the admin UID as the document id and values like:

```json
{
   "uid": "<same-auth-uid>",
   "name": "Admin",
   "email": "admin@actechs.pk",
   "role": "admin",
   "isActive": true,
   "language": "en",
   "createdAt": "server timestamp"
}
```

The `role` and `isActive` fields are critical. If they are missing or incorrect, login may succeed but authorization will fail.

## 9. Create Technician Records

Each technician needs:

- a Firebase Auth account
- a matching `users/{uid}` document
- role set to `technician`
- `isActive: true`

The app expects the Firestore user record to exist and uses it for role detection, language, and active-state checks.

## 10. Create Operational Seed Data

Before full testing, create at least:

- one company in `companies`
- one `app_settings/approval_config` document

### Suggested `approval_config` baseline

```json
{
   "jobApprovalRequired": false,
   "sharedJobApprovalRequired": false,
   "inOutApprovalRequired": false,
   "enforceMinimumBuild": false,
   "minSupportedBuildNumber": 1
}
```

This matches the current app defaults and avoids confusing approval behavior during initial rollout.

## 11. Shared Install Setup Notes

The current shared-install flow is not based on querying all peer jobs. It uses a dedicated aggregate document.

That means:

- the `shared_install_aggregates` rules must be deployed
- technicians must submit using the same shared invoice group and same invoice totals
- a mismatch in total units, bracket count, or delivery split values will be blocked intentionally
- if an admin rejects a shared job, the reserved aggregate share is released back to the pool

If shared installs fail with `permission-denied`, the most likely causes are:

- outdated Firestore rules in the project
- missing `shared_install_aggregates` rule block
- incorrect technician role data in `users`
- running an older client build against newer backend expectations

## 12. Validation Checklist

After setup, verify these paths:

### Auth

- admin can sign in
- technician can sign in
- inactive technician is blocked

### Jobs

- solo technician job saves correctly
- duplicate invoice is rejected for the same technician/company scope
- pending/approved behavior follows `approval_config`

### Shared Install

- first technician can create a shared invoice group
- second technician can submit against the same group
- aggregate blocks over-allocation correctly
- admin rejection releases shared capacity

### Admin Operations

- admin approvals list loads
- analytics load without rule failures
- company branding settings can be updated

## 13. Troubleshooting

### Permission Denied On Login Or Reads

Check:

- `users/{uid}` exists
- `role` is correct
- `isActive` is true
- the deployed rules match the repository rules

### Shared Installs Still Failing

Check:

- `shared_install_aggregates` exists in deployed rules
- all technicians are using the same shared invoice totals
- the client build is current

### No Firebase App Error

Ensure `Firebase.initializeApp()` is called before `runApp()` and that `firebase_options.dart` matches the current Firebase project.

### Index Errors

If Firestore returns an index URL during testing:

1. Create the required index.
2. Export the updated index definition back into `firestore.indexes.json`.
3. Commit it with the related feature change.

### Offline Behavior Looks Wrong

Firestore persistence is expected to handle local caching automatically. If behavior differs, inspect app initialization and avoid manual destructive cache handling on sign-out.

## 14. Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
firebase deploy --only firestore --project actechs-d415e
```
