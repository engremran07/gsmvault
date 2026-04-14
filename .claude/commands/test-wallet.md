# /test-wallet â€” Test wallet and financial operations

Verify financial integrity: select_for_update on mutations, transaction.atomic on multi-model ops, balance consistency, and race condition prevention.

## Scope

$ARGUMENTS

## Checklist

### Step 1: select_for_update Usage

- [ ] Grep `apps/wallet/` for all balance mutation points

- [ ] Verify every balance change uses `select_for_update()`

- [ ] Check `apps/shop/` order payment flows use `select_for_update()`

- [ ] Check `apps/marketplace/` transaction flows use `select_for_update()`

- [ ] Check `apps/bounty/` reward disbursement uses `select_for_update()`

### Step 2: transaction.atomic Coverage

- [ ] Verify all multi-model financial operations wrap in `@transaction.atomic`

- [ ] Check credit/debit operations are atomic

- [ ] Verify order creation + payment deduction are in same transaction

- [ ] Check referral reward crediting is atomic

### Step 3: Balance Integrity

- [ ] Verify no negative balance is possible (check constraints or validation)

- [ ] Test credit + debit = expected final balance

- [ ] Verify idempotency on retry (duplicate transaction prevention)

- [ ] Check decimal precision handling (no floating point for currency)

### Step 4: Race Condition Prevention

- [ ] Verify concurrent requests cannot double-spend credits

- [ ] Check that `select_for_update()` locks prevent parallel deductions

- [ ] Review any optimistic locking patterns

### Step 5: Audit Trail

- [ ] Verify all wallet transactions create audit records

- [ ] Check transaction logs include: user, amount, type, timestamp, reference

- [ ] Verify refund operations create reverse entries

### Step 6: Run Financial Tests

- [ ] Run `& .\.venv\Scripts\python.exe -m pytest apps/wallet/ apps/shop/ apps/marketplace/ apps/bounty/ -v --tb=short`

- [ ] Report results and any failures
