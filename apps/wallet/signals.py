"""apps.wallet.signals — Auto-create wallet on user signup."""

from __future__ import annotations

import logging
from typing import Any

from django.conf import settings
from django.db.models.signals import post_save
from django.dispatch import receiver

logger = logging.getLogger(__name__)


@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_wallet_on_signup(
    sender: type, instance: Any, created: bool, **kwargs: Any
) -> None:
    """Ensure every new user gets a wallet."""
    if created:
        from .services import get_or_create_wallet

        get_or_create_wallet(instance)
        logger.info("Wallet auto-created for user %s", instance.pk)
