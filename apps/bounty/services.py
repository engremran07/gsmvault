"""apps.bounty.services — Business logic for bounty lifecycle.

All mutating operations are atomic.  Wallet escrow is locked when the
bounty carries a reward, and released/refunded on resolution or
cancellation.
"""

from __future__ import annotations

import logging
from decimal import Decimal, InvalidOperation
from typing import TYPE_CHECKING

from django.db import transaction

from .models import BountyEscrow, BountyRequest, BountySubmission

if TYPE_CHECKING:
    from django.contrib.auth.models import AbstractBaseUser

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Bounty creation
# ---------------------------------------------------------------------------


def create_bounty(
    *,
    user: AbstractBaseUser,
    title: str,
    description: str,
    request_type: str = BountyRequest.RequestType.FIRMWARE,
    what_tried: str = "",
    fw_version_wanted: str = "",
    reward_amount: Decimal | float | str = 0,
    brand_id: int | str | None = None,
    device_model_id: int | str | None = None,
) -> BountyRequest:
    """Create a bounty and, when a reward is set, lock escrow from the creator's wallet.

    Returns the persisted :class:`BountyRequest`.

    Raises
    ------
    apps.wallet.services.InsufficientFundsError
        When the user's wallet cannot cover the reward.
    """
    try:
        reward = max(Decimal("0"), Decimal(str(reward_amount)))
    except (InvalidOperation, ValueError, TypeError):
        reward = Decimal("0")

    with transaction.atomic():
        bounty = BountyRequest.objects.create(
            user=user,
            title=title,
            request_type=request_type,
            description=description,
            what_tried=what_tried,
            fw_version_wanted=fw_version_wanted,
            reward_amount=reward,
            brand_id=brand_id or None,
            device_model_id=device_model_id or None,
        )

        # Lock escrow if reward > 0
        if reward > 0:
            _lock_bounty_escrow(bounty, user, reward)

        # Auto-create linked forum topic
        _create_forum_topic(bounty, user)

    return bounty


# ---------------------------------------------------------------------------
# Resolution & payout
# ---------------------------------------------------------------------------


def resolve_bounty(
    bounty: BountyRequest,
    *,
    resolution_type: str,
    resolution_note: str = "",
) -> None:
    """Mark *bounty* as fulfilled and release escrow to the accepted contributor(s).

    If ``resolution_type`` is ``single``, the single accepted submission's
    author receives the full reward.  For ``multiple``, the reward is split
    equally among all accepted submissions.  For ``self_with_ideas``, escrow
    is refunded to the bounty creator.
    """
    with transaction.atomic():
        bounty.status = BountyRequest.Status.FULFILLED
        bounty.resolution_type = resolution_type
        bounty.resolution_note = resolution_note
        bounty.save(
            update_fields=[
                "status",
                "resolution_type",
                "resolution_note",
                "updated_at",
            ]
        )

        try:
            escrow = bounty.escrow  # type: ignore[attr-defined]
        except BountyEscrow.DoesNotExist:
            return  # No reward attached — nothing to disburse

        if escrow.status != BountyEscrow.Status.HOLDING:
            return

        if resolution_type == BountyRequest.ResolutionType.SELF_WITH_IDEAS:
            _refund_escrow(escrow)
            return

        accepted = list(
            BountySubmission.objects.filter(
                request=bounty,
                status=BountySubmission.Status.ACCEPTED,
            ).select_related("user")
        )
        if not accepted:
            _refund_escrow(escrow)
            return

        _release_to_contributors(escrow, accepted)


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------


def _lock_bounty_escrow(
    bounty: BountyRequest,
    user: AbstractBaseUser,
    amount: Decimal,
) -> BountyEscrow:
    """Lock wallet funds and create a :class:`BountyEscrow` record."""
    from apps.wallet.services import get_or_create_wallet, lock_escrow

    wallet = get_or_create_wallet(user)
    escrow_hold = lock_escrow(
        wallet,
        amount,
        reason=f"Bounty #{bounty.pk} reward escrow",
        reference=f"bounty:{bounty.pk}",
    )
    return BountyEscrow.objects.create(
        request=bounty,
        amount=amount,
        status=BountyEscrow.Status.HOLDING,
        wallet_reference=str(escrow_hold.pk),
    )


def _refund_escrow(escrow: BountyEscrow) -> None:
    """Cancel the wallet escrow hold and mark bounty escrow as refunded."""
    from apps.wallet.models import EscrowHold
    from apps.wallet.services import cancel_escrow

    try:
        hold = EscrowHold.objects.get(pk=int(escrow.wallet_reference))
        cancel_escrow(hold)
    except (EscrowHold.DoesNotExist, ValueError):
        logger.warning(
            "Could not find wallet EscrowHold %s for bounty escrow %s",
            escrow.wallet_reference,
            escrow.pk,
        )
    escrow.status = BountyEscrow.Status.REFUNDED
    escrow.save(update_fields=["status"])


def _release_to_contributors(
    escrow: BountyEscrow,
    accepted_submissions: list[BountySubmission],
) -> None:
    """Release escrowed funds to one or more accepted contributors."""
    from apps.wallet.models import EscrowHold
    from apps.wallet.services import (
        cancel_escrow,
        credit,
        get_or_create_wallet,
    )

    # Release the wallet-level hold first (returns funds to creator's balance)
    try:
        hold = EscrowHold.objects.get(pk=int(escrow.wallet_reference))
        cancel_escrow(hold)
    except (EscrowHold.DoesNotExist, ValueError):
        logger.warning(
            "Could not find wallet EscrowHold %s — skipping unlock",
            escrow.wallet_reference,
        )

    # Debit creator and credit each contributor their share
    from apps.wallet.services import debit

    share_count = len(accepted_submissions)
    share_amount = escrow.amount / share_count

    creator_wallet = get_or_create_wallet(escrow.request.user)
    for sub in accepted_submissions:
        debit(
            creator_wallet,
            share_amount,
            description=f"Bounty #{escrow.request_id} payout to {sub.user}",  # type: ignore[attr-defined]
            reference=f"bounty:{escrow.request_id}:payout",  # type: ignore[attr-defined]
        )
        contributor_wallet = get_or_create_wallet(sub.user)
        credit(
            contributor_wallet,
            share_amount,
            description=f"Bounty #{escrow.request_id} reward",  # type: ignore[attr-defined]
            reference=f"bounty:{escrow.request_id}:reward",  # type: ignore[attr-defined]
        )

    escrow.status = BountyEscrow.Status.RELEASED
    escrow.save(update_fields=["status"])


def _create_forum_topic(bounty: BountyRequest, user: AbstractBaseUser) -> None:
    """Auto-create a ForumTopic linked to the bounty request."""
    try:
        from apps.forum.models import ForumCategory
        from apps.forum.services import create_topic

        category = None
        if bounty.brand_id:  # type: ignore[attr-defined]
            category = ForumCategory.objects.filter(
                brand_link_id=bounty.brand_id,  # type: ignore[attr-defined]
            ).first()
        if category is None:
            category = ForumCategory.objects.filter(slug="firmware-requests").first()
        if category is None:
            category = ForumCategory.objects.filter(slug="general").first()
        if category is None:
            logger.warning(
                "No forum category found for bounty %s — skipping topic creation",
                bounty.pk,
            )
            return

        type_label = bounty.get_request_type_display()  # type: ignore[attr-defined]
        content = f"**{type_label}:** {bounty.title}\n\n{bounty.description}"
        if bounty.fw_version_wanted:
            content += f"\n\n**Firmware wanted:** {bounty.fw_version_wanted}"
        if bounty.reward_amount > 0:
            content += f"\n\n**Reward:** {bounty.reward_amount:,.0f} credits"

        topic = create_topic(
            user=user,
            category=category,
            title=bounty.title,
            content=content,
        )
        BountyRequest.objects.filter(pk=bounty.pk).update(forum_topic=topic)
        logger.info("Auto-created forum topic %s for bounty %s", topic.pk, bounty.pk)
    except Exception:
        logger.exception("Failed to create forum topic for bounty %s", bounty.pk)
