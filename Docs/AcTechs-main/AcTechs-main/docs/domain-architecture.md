# Domain Architecture

## Three separate business domains

| Domain | Collections | Primary models | UI ownership |
| --- | --- | --- | --- |
| Jobs | `jobs`, `invoice_claims`, `shared_install_aggregates` | `JobModel`, `SharedInstallAggregate` | `features/jobs`, technician dashboard/history, admin approvals/analytics |
| In/Out | `expenses`, `earnings` | `ExpenseModel`, `EarningModel` | `features/expenses`, Daily In/Out, monthly summary |
| AC installs | `ac_installs` | `AcInstallModel` | `features/expenses`, AC installations screen |

## Why this separation exists

- Jobs represent invoice-based field work for customers.
- In/Out represents technician personal daily money in and money out.
- AC installs represent unit-install records that have their own approval and archive behavior.

The domains look adjacent in the UI but they do not share storage or provider ownership.

## Enforced boundaries

- Repositories stay collection-specific.
- In/Out day views derive from monthly providers instead of opening extra listeners.
- Job history and In/Out history use separate navigation flows.
- Firestore rules validate each domain independently.

## Navigation ownership

- Technician root tabs: home, submit, in/out, history, settings
- Admin root tabs: dashboard, approvals, analytics, team
- Settings, summary, settlement, import, companies, flush, and detail screens are pushed flows when they are not root tabs
