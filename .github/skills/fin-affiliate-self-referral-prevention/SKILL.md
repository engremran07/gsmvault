---
name: fin-affiliate-self-referral-prevention
description: "Self-referral detection and prevention. Use when: blocking users from earning affiliate commissions on their own purchases, preventing referral abuse."
---

# Self-Referral Prevention

## When to Use

- Validating affiliate conversions before crediting commission
- Detecting users referring themselves through alternate accounts
- Blocking referral code use by the code owner

## Rules

1. **Direct self-referral** — user cannot use their own affiliate link/code
2. **IP match detection** — flag if referrer and converter share IP
3. **Household detection** — flag same billing address/payment method
4. **Cool-down period** — new accounts cannot earn commissions immediately
5. **Manual review queue** — suspicious conversions go to admin, not auto-paid

## Pattern: Self-Referral Checks

```python
from apps.ads.models import AffiliateLink, AffiliateClick
from apps.core.utils import get_client_ip

def check_self_referral(
    affiliate_user_id: int,
    converter_user_id: int,
    converter_ip: str,
) -> dict:
    """Check for self-referral indicators. Returns risk assessment."""
    flags = []

    # Direct match
    if affiliate_user_id == converter_user_id:
        flags.append("direct_self_referral")

    # IP match — referrer's recent IPs vs converter IP
    referrer_ips = set(
        AffiliateClick.objects
        .filter(affiliate_link__user_id=affiliate_user_id)
        .values_list("ip_address", flat=True)
        .distinct()[:50]
    )
    if converter_ip in referrer_ips:
        flags.append("shared_ip_address")

    # Account age check
    from apps.users.models import User
    from django.utils import timezone
    from datetime import timedelta
    affiliate = User.objects.get(pk=affiliate_user_id)
    if (timezone.now() - affiliate.date_joined) < timedelta(days=7):
        flags.append("new_affiliate_account")

    risk_level = "high" if "direct_self_referral" in flags else (
        "medium" if flags else "low"
    )
    return {
        "flags": flags,
        "risk_level": risk_level,
        "requires_review": risk_level in ("high", "medium"),
    }
```

## Pattern: Gated Commission

```python
from django.db import transaction

@transaction.atomic
def process_affiliate_conversion(
    click_id: int,
    converter_user_id: int,
    converter_ip: str,
    order_amount,
) -> dict:
    """Process conversion with self-referral gate."""
    click = AffiliateClick.objects.get(pk=click_id)
    affiliate_user_id = click.affiliate_link.user_id

    risk = check_self_referral(affiliate_user_id, converter_user_id, converter_ip)

    if risk["risk_level"] == "high":
        click.status = "rejected"
        click.rejection_reason = ", ".join(risk["flags"])
        click.save(update_fields=["status", "rejection_reason"])
        return {"status": "rejected", "flags": risk["flags"]}

    if risk["requires_review"]:
        click.status = "pending_review"
        click.save(update_fields=["status"])
        return {"status": "pending_review", "flags": risk["flags"]}

    # Clean — auto-approve
    return {"status": "approved", "flags": []}
```

## Anti-Patterns

| Bad | Why | Fix |
|-----|-----|-----|
| Only checking `user_id == user_id` | Misses alt accounts | Check IP + account age |
| Auto-approving all conversions | Self-referral abuse | Risk assessment gate |
| Blocking without logging reason | Admin can't review | Record rejection reason |

## Red Flags

- No self-referral checks before commission credit
- Missing IP-based detection
- Auto-payout without review queue for flagged conversions

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
