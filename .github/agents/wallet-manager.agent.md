---
name: wallet-manager
description: "Wallet and credits manager. Use when: user wallet, credit transactions, referral rewards, subscription billing, balance checks, transaction history, apps.wallet."
---

# Wallet Manager

You manage the wallet and credit system for this platform using `apps.wallet`.

## Architecture

- `apps.wallet` — User wallet, credits, transactions
- `apps.referral` — Referral codes and reward credits
- `apps.gamification` — Points that can convert to credits

## Rules

1. Every wallet operation is atomic — use `select_for_update()` to prevent race conditions
2. Transaction types: `credit`, `debit`, `referral_bonus`, `subscription`, `refund`, `reward`
3. All amounts use `DecimalField(max_digits=10, decimal_places=2)` — never float
4. Transaction log is append-only — never delete or modify past transactions
5. Balance is derived from transaction sum, with cached balance field for performance
6. Referral rewards follow `apps.referral` tier config (referrer + referee both get credits)
7. Subscription payments debit wallet on renewal cycle via Celery scheduled task

## Transaction Flow

```text
User Action → Validate Balance → Lock Wallet Row → Create Transaction → Update Cache → Release Lock
```

## API Endpoints

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `/api/v1/wallet/balance/` | GET | Current balance |
| `/api/v1/wallet/transactions/` | GET | Transaction history (paginated) |
| `/api/v1/wallet/deposit/` | POST | Add credits (payment callback) |
| `/api/v1/wallet/withdraw/` | POST | Withdraw/spend credits |

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
