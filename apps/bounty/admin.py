from django.contrib import admin

from .models import (
    BountyEscrow,
    BountyRequest,
    BountySubmission,
    FraudCheck,
    PeerReview,
)


@admin.register(BountyRequest)
class BountyRequestAdmin(admin.ModelAdmin[BountyRequest]):
    list_display = [
        "pk",
        "title",
        "request_type",
        "user",
        "reward_amount",
        "status",
        "resolution_type",
        "created_at",
    ]
    list_filter = ["status", "request_type", "resolution_type"]
    search_fields = ["title", "description", "fw_version_wanted", "user__email"]


@admin.register(BountySubmission)
class BountySubmissionAdmin(admin.ModelAdmin[BountySubmission]):
    list_display = ["pk", "request", "user", "is_confirmed", "status", "created_at"]
    list_filter = ["status", "is_confirmed"]


@admin.register(PeerReview)
class PeerReviewAdmin(admin.ModelAdmin[PeerReview]):
    list_display = ["submission", "reviewer", "verdict", "created_at"]
    list_filter = ["verdict"]


@admin.register(BountyEscrow)
class BountyEscrowAdmin(admin.ModelAdmin[BountyEscrow]):
    list_display = ["request", "amount", "status", "created_at"]


@admin.register(FraudCheck)
class FraudCheckAdmin(admin.ModelAdmin[FraudCheck]):
    list_display = ["submission", "score", "passed", "checked_at"]
    list_filter = ["passed"]
