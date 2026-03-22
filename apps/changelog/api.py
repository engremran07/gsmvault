"""apps.changelog API — DISSOLVED. Viewsets moved to apps.firmwares.api."""

# Re-export for any existing imports.
from apps.firmwares.api import (
    ChangelogEntrySerializer,
    ChangelogEntryViewSet,
    FirmwareDiffSerializer,
    FirmwareDiffViewSet,
)

__all__ = [
    "ChangelogEntrySerializer",
    "ChangelogEntryViewSet",
    "FirmwareDiffSerializer",
    "FirmwareDiffViewSet",
]
