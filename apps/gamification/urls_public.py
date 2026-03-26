"""Gamification public page URLs (mounted at /rewards/)."""

from django.urls import path

from . import views

app_name = "gamification_public"

urlpatterns = [
    path("", views.my_progress, name="my_progress"),
    path("badges/", views.badge_showcase, name="badge_showcase"),
    path("leaderboard/", views.global_leaderboard, name="leaderboard"),
]
