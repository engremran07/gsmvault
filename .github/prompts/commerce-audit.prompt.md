---
agent: 'agent'
description: 'Audit financial safety across wallet, shop, marketplace, bounty, referral, gamification, and download quota systems'
tools: ['semantic_search', 'read_file', 'grep_search', 'file_search']
---

# Commerce & Financial Safety Audit

Audit all financial and commerce systems in the GSMFWs platform for data integrity, concurrency safety, and abuse prevention.

## 1 — Wallet Concurrency Safety

### select_for_update on Balance Mutations
Every function in `apps/wallet/services*.py` that modifies wallet balances MUST use `select_for_update()`:

```python
# REQUIRED pattern
with transaction.atomic():
    wallet = Wallet.objects.select_for_update().get(user=user)
    wallet.balance += amount
    wallet.save()
```

Grep for wallet balance changes (`wallet.balance`, `balance +=`, `balance -=`, `.update(balance=`) without preceding `select_for_update()`. Each is a CRITICAL finding.

### Debit Insufficiency Check
Before any debit, verify `wallet.balance >= amount`. Never allow negative balances.

## 2 — transaction.atomic Enforcement

### Multi-Model Writes
Every service function in `apps/*/services*.py` that writes to 2+ models must be wrapped in `@transaction.atomic` or `with transaction.atomic():`.

Search for multi-model operations in:
- `apps/wallet/` — credit/debit + transaction log
- `apps/shop/` — order creation + inventory update + wallet debit
- `apps/marketplace/` — listing + escrow + transaction
- `apps/bounty/` — bounty claim + reward + wallet credit
- `apps/referral/` — referral record + reward credit
- `apps/gamification/` — points award + badge check + leaderboard update
- `apps/ads/` — rewarded ad view + credit grant

## 3 — Escrow Safety (Marketplace)

Verify the marketplace P2P transaction flow:
1. **Escrow Hold** — Buyer's funds locked via `select_for_update()` + balance deduction
2. **Escrow Release** — Funds transferred to seller only on buyer confirmation
3. **Dispute Handling** — Admin can mediate and split/refund escrow
4. **Timeout** — Unclaimed escrow auto-released or refunded after deadline

Check that escrow operations:
- Cannot double-release (idempotency guard)
- Cannot release to wrong user
- Have audit trail entries

## 4 — Subscription Tier Enforcement

Verify download quota enforcement in `apps/firmwares/download_service.py`:
1. User's `QuotaTier` is loaded from `apps/devices`
2. Daily/hourly limits checked before `DownloadToken` creation
3. Ad-gate required for free tier (`requires_ad` flag)
4. Expired tokens are properly marked (`status = "expired"`)
5. Used tokens cannot be reused (`status = "used"`)

Tier hierarchy: Free → Registered → Subscriber → Premium. Verify each tier has progressively higher limits.

## 5 — Affiliate Self-Referral Prevention

In `apps/ads/services/affiliate.py`:
1. Check that click attribution excludes the affiliate's own user account
2. Verify conversion tracking skips self-referral purchases
3. Commission calculation excludes self-purchases

Grep for affiliate earning without ownership check.

## 6 — Promo Code Limits

In `apps/shop/` or relevant promo code service:
1. **Per-user limit** — Each promo code has max uses per user
2. **Total limit** — Each promo code has total redemption cap
3. **Expiry** — Expired promo codes rejected at validation
4. **Stacking rules** — Verify policy on combining multiple promo codes
5. **Amount validation** — Discount cannot exceed order total

## 7 — Download Quota Enforcement

Verify the complete download gating flow:
1. `check_rate_limit()` — Per-user download rate within tier limits
2. `create_download_token()` — HMAC-signed token with expiry
3. `validate_download_token()` — Signature verification + expiry check + status check
4. `complete_ad_gate()` — Ad completion recorded before download unlock (free tier)
5. `check_hotlink_protection()` — Referrer validation against allowed domains
6. `start_download_session()` → `complete_download_session()` — Full lifecycle tracking

Verify WAF rate limits (`apps.security`) are **NOT** imported or used in firmware download code. These are separate systems.

## 8 — Gamification Caps

In `apps/gamification/`:
1. **Daily point caps** — Maximum points earnable per day per user
2. **Action cooldowns** — Minimum interval between point-earning actions
3. **Badge abuse prevention** — Badge criteria cannot be gamed (e.g., self-upvoting)
4. **Leaderboard integrity** — Points from banned/suspended users excluded

## 9 — Double-Entry Ledger

Financial transactions should create balanced entries:
- Every credit has a matching debit somewhere
- System balance (sum of all wallets) matches total deposits minus withdrawals
- Admin adjustments create separate ledger entries with justification

## 10 — Financial Audit Trail

Every financial operation must record:
- User who initiated
- Timestamp
- Amount and currency
- Transaction type (credit, debit, transfer, refund, reward)
- Reference to source (order, bounty, referral, ad view)
- IP address of requester

Check `apps/wallet/` models for complete audit trail fields.

## Report Format

```
[CRITICAL] Category — Description
  File: apps/wallet/services.py:LINE
  Risk: What could go wrong (e.g., "Race condition allows double-spending")
  Fix: Specific code change required
```

Severity guide:
- **CRITICAL** — Data loss, financial inconsistency, race conditions
- **HIGH** — Abuse vectors, missing limits, bypass possibilities
- **MEDIUM** — Missing audit trail, incomplete validation
- **LOW** — Style issues, missing type hints in financial code
