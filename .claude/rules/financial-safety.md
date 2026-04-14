---
paths: ["apps/wallet/**", "apps/shop/**", "apps/marketplace/**", "apps/bounty/**"]
---

# Financial Safety

All financial operations MUST be protected against race conditions, precision loss, and audit gaps. Money handling is zero-tolerance for errors.

## Concurrency Protection

- ALWAYS use `select_for_update()` when reading wallet/credit balances before modification — this prevents race conditions on concurrent requests.
- ALWAYS wrap multi-model financial operations in `@transaction.atomic` — partial writes are catastrophic.
- NEVER read a balance, compute a new value, and write it back without `select_for_update()` — this is a classic TOCTOU race.
- For testing concurrent access patterns: use `TransactionTestCase`, not `TestCase`.

## Decimal Precision

- ALWAYS use `Decimal` for all monetary values — NEVER use `float` (IEEE 754 rounding errors).
- Model fields: `DecimalField(max_digits=12, decimal_places=2)` minimum.
- Calculations: use `Decimal` arithmetic throughout — never cast to `float` mid-computation.
- String-to-Decimal: `Decimal("10.50")` — NEVER `Decimal(10.50)` (float constructor loses precision).
- Display: format with `quantize(Decimal("0.01"))` for user-facing output.

## Double-Entry Accounting

- Every debit MUST have a corresponding credit — the system MUST balance.
- Create both sides of a transaction in the same `@transaction.atomic` block.
- Refunds: reverse the original transaction by creating inverse entries — NEVER subtract directly from a balance field.
- Escrow: hold funds in an escrow account, then release atomically upon fulfillment.

## Audit Trail

- Every financial operation MUST create a log entry with: user, amount, type, timestamp, and related object.
- NEVER delete financial records — use soft-delete or status flags (`cancelled`, `reversed`).
- Admin adjustments MUST record the admin user who performed the action.
- Reconciliation: periodic tasks should verify balance consistency.

## Validation Rules

- NEVER allow negative wallet balances — check before debit and reject if insufficient.
- Maximum transaction limits: enforce per-tier caps in the service layer.
- Duplicate detection: use idempotency keys for payment processing endpoints.
- Currency: store currency code alongside amount if multi-currency is supported.
