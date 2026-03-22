from rest_framework.routers import DefaultRouter

from .api import LedgerEntryViewSet, PayoutRequestViewSet, WalletViewSet

app_name = "wallet"

router = DefaultRouter()
router.register("wallets", WalletViewSet, basename="wallets")
router.register("ledger", LedgerEntryViewSet, basename="ledger")
router.register("payouts", PayoutRequestViewSet, basename="payouts")

urlpatterns = router.urls
