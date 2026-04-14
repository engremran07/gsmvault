---
name: api-design
description: "Design REST API endpoints with Django REST Framework. Use when: creating serializers, viewsets, routers, custom permissions, pagination, filtering, or API versioning for the platform."
user-invocable: true
---

# API Design

> Full reference: @.github/skills/api-design/SKILL.md

## Quick Rules

- NEVER `fields = "__all__"` in serializers — enumerate fields explicitly
- Business logic in `services.py` — NOT in views or serializers
- All list endpoints require pagination
- All mutating endpoints require `permission_classes = [permissions.IsAuthenticated]`
- Error responses: `{"error": "...", "code": "..."}` format
- All endpoints under `/api/v1/` prefix

## Serializer Pattern

```python
class MyModelSerializer(serializers.ModelSerializer):
    class Meta:
        model = MyModel
        fields = ["id", "name", "status", "created_at"]
        read_only_fields = ["id", "created_at"]
```

## ViewSet Pattern

```python
class MyModelViewSet(viewsets.ModelViewSet):
    queryset = MyModel.objects.select_related("owner").all()
    serializer_class = MyModelSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["name"]
    ordering = ["-created_at"]

    def perform_create(self, serializer):
        from .services import create_my_model
        create_my_model(serializer.validated_data, user=self.request.user)
```

## Router Registration (in `urls.py`)

```python
from rest_framework.routers import DefaultRouter
router = DefaultRouter()
router.register("my-models", MyModelViewSet, basename="mymodel")
app_name = "myapp"
urlpatterns = router.urls
```
