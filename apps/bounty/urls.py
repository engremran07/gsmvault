"""Bounty public page URLs (mounted at /bounty/)."""

from django.urls import path

from . import views

app_name = "bounty"

urlpatterns = [
    path("", views.bounty_list, name="bounty_list"),
    path("create/", views.bounty_create, name="bounty_create"),
    path("<int:pk>/", views.bounty_detail, name="bounty_detail"),
    path(
        "<int:pk>/submit/",
        views.bounty_submit_solution,
        name="bounty_submit_solution",
    ),
    path(
        "<int:pk>/confirm/<int:submission_id>/",
        views.bounty_confirm_solution,
        name="bounty_confirm_solution",
    ),
    path("<int:pk>/resolve/", views.bounty_resolve, name="bounty_resolve"),
]
