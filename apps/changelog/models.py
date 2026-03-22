"""apps.changelog — DISSOLVED. Models absorbed into apps.firmwares.

Import from apps.firmwares instead:
  from apps.firmwares.models import ChangelogEntry, ReleaseNote, FirmwareDiff
"""

# Re-export for any code that still imports from this module.
from apps.firmwares.models import ChangelogEntry, FirmwareDiff, ReleaseNote

__all__ = ["ChangelogEntry", "ReleaseNote", "FirmwareDiff"]
