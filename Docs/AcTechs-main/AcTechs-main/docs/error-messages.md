# AC Techs — Error And Feedback Catalog

This document summarizes the app's current error and feedback strategy at a product level. The goal is operational clarity, not just string listing.

## Principles

- user-facing errors must be human-readable
- Firebase exception codes must not leak directly into the UI
- all important operational errors are localized in English, Urdu, and Arabic
- repositories convert backend failures into `AppException` types
- UI surfaces those errors through centralized feedback patterns

The source of truth for repository-level exceptions is `lib/core/models/app_exception.dart`.

## Exception Families

### Authentication

Used for sign-in, account state, email changes, password changes, and reset flows.

| Code | English |
| --- | --- |
| `auth_wrong_credentials` | Wrong username or password. Please check and try again. |
| `auth_account_disabled` | Your account has been deactivated. Contact your admin. |
| `auth_account_not_provisioned` | Your account is not available in app records. Contact your admin. |
| `auth_too_many_attempts` | Too many failed attempts. Please wait a few minutes. |
| `auth_session_expired` | Your session has expired. Please sign in again. |
| `auth_update_failed` | Could not update your profile. Please try again. |
| `auth_invalid_email` | Please enter a valid email address. |
| `auth_email_in_use` | This email is already in use by another account. |
| `auth_weak_password` | Password is too weak. Use at least 6 characters. |
| `auth_recent_login_required` | Please sign in again before changing sensitive account details. |
| `auth_reset_network` | No internet connection. Please connect and try again. |
| `auth_reset_rate_limit` | Too many reset requests. Please wait a few minutes and try again. |
| `auth_reset_failed` | Could not send reset email. Check the address and try again. |
| `auth_unknown` | Something went wrong. Please try again. |

### Network

Used when local work is valid but backend sync is blocked or delayed.

| Code | English |
| --- | --- |
| `network_offline` | You're offline. Your work is saved and will sync automatically when connected. |
| `network_sync_failed` | Couldn't sync your data. We'll retry automatically. |

### Jobs

Used by solo and shared install flows, approval-dependent save behavior, and repository validation.

| Code | English |
| --- | --- |
| `job_no_invoice` | Please enter an invoice number. |
| `job_no_units` | Add at least one AC unit before submitting. |
| `job_save_failed` | Couldn't save your job. We'll retry in a moment. |
| `job_duplicate_invoice` | A job with this invoice number already exists. |
| `job_shared_units_exceeded` | Shared units exceed invoice total. Remaining units are reported in the message. |
| `job_shared_type_units_exceeded` | A specific AC type or bracket share exceeds what remains on the shared invoice. |
| `job_shared_delivery_split_invalid` | The shared team size must be set before delivery can be split. |
| `job_shared_group_mismatch` | The same shared invoice group was reused with different totals. |
| `job_permission_denied` | Permission denied. Please contact your admin. |
| `job_backend_sync_in_progress` | Backend update is still syncing. Please retry in a minute. |

### Admin

Used for approvals, flush flows, password confirmation, and user management.

| Code | English |
| --- | --- |
| `admin_reject_no_reason` | Please add a reason so the technician knows what to fix. |
| `admin_no_permission` | You don't have admin access for this action. |
| `admin_flush_failed` | Database flush failed. Please check your connection and try again. |
| `admin_wrong_password` | Incorrect password. Please try again. |
| `admin_user_save_failed` | Couldn't save user changes. Please try again. |

### Expenses And Earnings

Used for daily IN/OUT records and edit/delete flows.

| Code | English |
| --- | --- |
| `expense_save_failed` | Couldn't save your entry. Please check your connection and try again. |
| `expense_delete_failed` | Couldn't delete the entry. Please try again. |
| `user_save_failed` | Couldn't save changes. Please try again. |
| `earning_save_failed` | Couldn't save your earning. Please check your connection and try again. |
| `earning_delete_failed` | Couldn't delete the earning. Please try again. |
| `earning_update_failed` | Couldn't save changes to the earning. Please try again. |

### AC Install Records

Used for the separate installation tracking flow.

| Code | English |
| --- | --- |
| `ac_install_save_failed` | Couldn't save the installation record. Please check your connection and try again. |
| `ac_install_delete_failed` | Couldn't delete the installation record. Please try again. |
| `ac_install_update_failed` | Couldn't update the installation record. Please try again. |

### Period Lock

Used when a tech attempts to archive or edit a record that falls in an admin-locked time period.

| Code | English |
| --- | --- |
| `period_locked` | This record falls in a locked period. Ask your admin to unlock it first. |

## Shared Install Error Semantics

These are the high-value messages for current field support and admin debugging:

- `job_shared_type_units_exceeded`
  Use when a technician's split, window, freestanding, or bracket share exceeds the remaining allowance for the invoice group.

- `job_shared_delivery_split_invalid`
  Use when delivery exists but the team size is missing or invalid.

- `job_shared_group_mismatch`
  Use when technicians attempt to submit to the same shared invoice group with different invoice totals. This is intentional protection, not a backend failure.

- `job_permission_denied`
  If this appears after the shared-install migration, first suspect outdated Firestore rules or stale client builds.

## Success Feedback Patterns

The app now distinguishes between approval-required and direct-save outcomes.

### Job Outcomes

- `jobSubmitted`
  Used when a job is created in `pending` status and is waiting for admin approval.

- `jobSaved`
  Used when approval is disabled and the job is written directly as approved.

### IN/OUT Entries

- `entriesSaved`
  Used after successfully saving daily entries.

- `entryUpdated`
  Used after updating an earning or expense entry.

- `entryDeleted`
  Used after deleting an earning or expense entry.

## Operational Notes For Support

### If A Technician Reports "Permission Denied"

Check, in order:

1. user document exists in `users`
2. role is correct
3. account is active
4. Firestore rules are current
5. the client build is current enough for the shared-install aggregate flow

### If A Shared Install Fails But Solo Jobs Work

Most likely causes:

1. shared invoice totals are inconsistent across technicians
2. aggregate rules are not deployed
3. a previous rejected job did not come from the updated release path

### If A Technician Says A Job Was Saved But Not Visible In Pending

Check approval configuration:

- `jobApprovalRequired`
- `sharedJobApprovalRequired`
- `inOutApprovalRequired`

The current product behavior allows direct save when these toggles are off.

## Product-Level UI Messaging Examples

These are important user-facing messages that changed recently and should remain consistent:

- job submitted successfully and waiting for admin approval
- entry added successfully
- entries saved successfully
- entry deleted successfully
- built and supported for AC Techs
- developed by Muhammad Imran

## Maintenance Guidance

When changing error handling:

1. update `app_exception.dart` first
2. update the relevant repository mapping from Firebase exceptions
3. update l10n strings if the message is shown directly in UI feedback
4. update this document if the change affects operational support or user troubleshooting
