---
applyTo: lib/features/expenses/**,lib/features/technician/presentation/job_history_screen.dart,lib/features/technician/presentation/daily_in_out_screen.dart
---

# In/Out Model Boundaries — AC Techs

## ⚠️ Three Separate Domains — NEVER Cross-Wire

| Domain | Collection | Model | providers file |
|--------|-----------|-------|---------------|
| Jobs | `jobs/` | `JobModel` | `job_providers.dart` |
| **In/Out** | `expenses/` + `earnings/` | `ExpenseModel` + `EarningModel` | **`expense_providers.dart`** |
| AC Installs | `ac_installs/` | `AcInstallModel` | own providers |

A `JobModel` doc contains NO expense/earning sub-documents.
Expense/earnings screens ONLY watch providers from `expense_providers.dart` — NEVER `job_providers.dart`.

## Provider Hierarchy (no extra Firestore listeners for sub-day views)

```
monthlyEarningsProvider(DateTime)   → StreamProvider.family  ← real listener
monthlyExpensesProvider(DateTime)   → StreamProvider.family  ← real listener
todaysEarningsProvider              → derived from monthly   ← no extra listener
todaysExpensesProvider              → derived from monthly   ← no extra listener
dailyEarningsProvider(DateTime)     → derived from monthly   ← no extra listener  
dailyExpensesProvider(DateTime)     → derived from monthly   ← no extra listener
```

NEVER create a new Firestore listener scoped to a single day. Always derive from monthly.

## DailyInOutScreen — selectedDate Pattern

```dart
// Constructor — selectedDate: null = today (form visible); selected = historical (form hidden)
const DailyInOutScreen({super.key, this.selectedDate});
final DateTime? selectedDate;

// In build():
final earningsAsync = selectedDate != null
    ? ref.watch(dailyEarningsProvider(selectedDate!))
    : ref.watch(todaysEarningsProvider);
```

## Navigation Rules

```
History In/Out card tap → context.push('/tech/inout', extra: theDate)  ✓
History In/Out card tap → context.push('/tech/summary', extra: theDate) ✗ WRONG (summary is read-only)
Bottom nav In/Out tab   → context.go('/tech/inout')  (no extra, shows today)
Monthly overview        → context.push('/tech/summary')
```

## In/Out Approval (separate from JobStatus)

- Uses `inOutApprovalRequired` from `ApprovalConfigModel` — NOT the same as job approval
- `EarningApprovalStatus` enum drives expense/earning approval states
- NEVER use `JobStatus` inside expense/earning code
