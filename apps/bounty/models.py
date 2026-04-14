"""apps.bounty — Firmware bounty & support forum system.

Two bounty types:
  - FIRMWARE: users request a specific firmware build
  - SUPPORT: technicians post flashing/unlocking problems;
    contributors provide solutions; reward after tech confirms resolution
"""

from __future__ import annotations

from django.conf import settings
from django.db import models


class BountyRequest(models.Model):
    """Bounty request — firmware request or support/troubleshooting thread."""

    class RequestType(models.TextChoices):
        FIRMWARE = "firmware", "Firmware Request"
        SUPPORT = "support", "Support / Troubleshooting"

    class Status(models.TextChoices):
        OPEN = "open", "Open"
        IN_PROGRESS = "in_progress", "In Progress"
        FULFILLED = "fulfilled", "Fulfilled"
        CLOSED = "closed", "Closed"
        EXPIRED = "expired", "Expired"

    class ResolutionType(models.TextChoices):
        PENDING = "pending", "Pending"
        SINGLE = "single", "Single Contributor"
        MULTIPLE = "multiple", "Multiple Contributors"
        SELF_WITH_IDEAS = "self_with_ideas", "Self-Resolved (Community Ideas)"

    # Core fields
    title = models.CharField(max_length=200, default="")
    request_type = models.CharField(
        max_length=20,
        choices=RequestType.choices,
        default=RequestType.FIRMWARE,
        db_index=True,
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="bounty_requests",
    )

    # Device context (optional — user picks brand/model for context)
    device = models.ForeignKey(
        "devices.Device",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="bounties",
    )
    brand = models.ForeignKey(
        "firmwares.Brand",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="bounty_requests",
    )
    device_model = models.ForeignKey(
        "firmwares.Model",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="bounty_requests",
    )

    # Content
    fw_version_wanted = models.CharField(max_length=100, blank=True, default="")
    description = models.TextField(help_text="Describe what you need or the issue.")
    what_tried = models.TextField(
        blank=True,
        default="",
        help_text="For support requests: what you have already tried.",
    )

    # Reward & status
    reward_amount = models.DecimalField(max_digits=14, decimal_places=4, default=0)
    status = models.CharField(
        max_length=12, choices=Status.choices, default=Status.OPEN, db_index=True
    )
    resolution_type = models.CharField(
        max_length=20,
        choices=ResolutionType.choices,
        default=ResolutionType.PENDING,
    )
    resolution_note = models.TextField(
        blank=True,
        default="",
        help_text="Technician's note on how the issue was resolved.",
    )

    expires_at = models.DateTimeField(null=True, blank=True)

    # Forum integration — auto-created on bounty creation
    forum_topic = models.ForeignKey(
        "forum.ForumTopic",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="bounty_requests",
        help_text="Auto-linked forum discussion for this bounty.",
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Bounty Request"
        verbose_name_plural = "Bounty Requests"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Bounty#{self.pk}: {self.title} [{self.status}]"

    @property
    def is_firmware_request(self) -> bool:
        return self.request_type == self.RequestType.FIRMWARE

    @property
    def is_support_request(self) -> bool:
        return self.request_type == self.RequestType.SUPPORT

    @property
    def confirmed_solutions_count(self) -> int:
        return self.submissions.filter(is_confirmed=True).count()  # type: ignore[attr-defined]


class BountySubmission(models.Model):
    """Solution/contribution to a bounty request."""

    class Status(models.TextChoices):
        SUBMITTED = "submitted", "Submitted"
        UNDER_REVIEW = "under_review", "Under Review"
        ACCEPTED = "accepted", "Accepted"
        REJECTED = "rejected", "Rejected"

    request = models.ForeignKey(
        BountyRequest, on_delete=models.CASCADE, related_name="submissions"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="bounty_submissions",
    )
    firmware = models.ForeignKey(
        "firmwares.OfficialFirmware",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="bounty_submissions",
    )
    notes = models.TextField(blank=True, default="")
    is_confirmed = models.BooleanField(
        default=False,
        help_text="Technician confirmed this solution helped resolve the issue.",
    )
    status = models.CharField(
        max_length=14, choices=Status.choices, default=Status.SUBMITTED, db_index=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Bounty Submission"
        verbose_name_plural = "Bounty Submissions"
        ordering = ["-created_at"]
        unique_together = [("request", "user")]

    def __str__(self) -> str:
        return f"Submission#{self.pk} for Bounty#{self.request_id} [{self.status}]"  # type: ignore[attr-defined]


class PeerReview(models.Model):
    """Community peer review of a bounty submission."""

    class Verdict(models.TextChoices):
        PASS = "pass", "Pass"
        FAIL = "fail", "Fail"
        NEEDS_MORE = "needs_more", "Needs More Info"

    submission = models.ForeignKey(
        BountySubmission, on_delete=models.CASCADE, related_name="peer_reviews"
    )
    reviewer = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="peer_reviews"
    )
    verdict = models.CharField(max_length=12, choices=Verdict.choices)
    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Peer Review"
        verbose_name_plural = "Peer Reviews"
        unique_together = [("submission", "reviewer")]

    def __str__(self) -> str:
        return f"Review by {self.reviewer} → {self.verdict}"


class BountyEscrow(models.Model):
    """Escrow record for bounty reward funds."""

    class Status(models.TextChoices):
        HOLDING = "holding", "Holding"
        RELEASED = "released", "Released"
        REFUNDED = "refunded", "Refunded"

    request = models.OneToOneField(
        BountyRequest, on_delete=models.CASCADE, related_name="escrow"
    )
    amount = models.DecimalField(max_digits=14, decimal_places=4)
    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.HOLDING
    )
    wallet_reference = models.CharField(max_length=200, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    released_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Bounty Escrow"
        verbose_name_plural = "Bounty Escrows"

    def __str__(self) -> str:
        return f"Escrow {self.amount} for Bounty#{self.request_id} [{self.status}]"  # type: ignore[attr-defined]


class FraudCheck(models.Model):
    """Anti-fraud scoring for a bounty submission."""

    submission = models.OneToOneField(
        BountySubmission, on_delete=models.CASCADE, related_name="fraud_check"
    )
    score = models.FloatField(default=0.0, help_text="0-100; higher = more suspicious")
    flags = models.JSONField(default=list, blank=True)
    passed = models.BooleanField(default=True)
    checked_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Fraud Check"
        verbose_name_plural = "Fraud Checks"

    def __str__(self) -> str:
        return f"FraudCheck score={self.score} {'OK' if self.passed else 'FLAGGED'}"
