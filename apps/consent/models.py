# apps/consent/models.py — compatibility shim
# Consent models dissolved into apps.users.
from apps.users.models import (  # noqa: F401
    ConsentCategory,
    ConsentDecision,
    ConsentEvent,
    ConsentLog,
    ConsentPolicy,
    ConsentRecord,
)

__all__ = [
    "ConsentPolicy",
    "ConsentDecision",
    "ConsentEvent",
    "ConsentRecord",
    "ConsentLog",
    "ConsentCategory",
]
