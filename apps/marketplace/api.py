from rest_framework import permissions, serializers, viewsets
from rest_framework.filters import OrderingFilter, SearchFilter

from .models import Listing, SellerProfile


class SellerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = SellerProfile
        fields = [
            "id",
            "user",
            "bio",
            "display_name",
            "verified",
            "rating",
            "total_sales",
        ]
        read_only_fields = ["id", "user", "verified", "rating", "total_sales"]


class ListingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Listing
        fields = [
            "id",
            "seller",
            "firmware",
            "title",
            "price",
            "discount_price",
            "is_featured",
            "is_active",
        ]
        read_only_fields = ["id", "seller"]


class SellerProfileViewSet(viewsets.ModelViewSet):
    serializer_class = SellerProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [SearchFilter]
    search_fields = ["display_name"]

    def get_queryset(self):
        if getattr(self.request.user, "is_staff", False):
            return SellerProfile.objects.all()
        return SellerProfile.objects.filter(user=self.request.user)


class ListingViewSet(viewsets.ModelViewSet):
    serializer_class = ListingSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [SearchFilter, OrderingFilter]
    search_fields = ["title"]

    def get_queryset(self):
        return Listing.objects.filter(is_active=True)
