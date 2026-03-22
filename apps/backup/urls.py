from rest_framework.routers import DefaultRouter

from .api import BackupFileViewSet, BackupScheduleViewSet

app_name = "backup"

router = DefaultRouter()
router.register("schedules", BackupScheduleViewSet, basename="schedules")
router.register("files", BackupFileViewSet, basename="files")

urlpatterns = router.urls
