# apps/core/models.py — compatibility shim
# Abstract base models dissolved into apps.users; AppRegistry moved to apps.site_settings.
from apps.site_settings.models import AppRegistry  # noqa: F401
from apps.users.models import (  # noqa: F401
    AuditFieldsModel,
    SoftDeleteModel,
    TimestampedModel,
)

__all__ = ["TimestampedModel", "SoftDeleteModel", "AuditFieldsModel", "AppRegistry"]
