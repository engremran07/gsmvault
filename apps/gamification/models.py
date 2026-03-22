"""apps.gamification — XP, levels, badges, streaks, leaderboards."""

from __future__ import annotations

from django.conf import settings
from django.db import models


class Level(models.Model):
    """XP threshold and label for each user level."""

    number = models.PositiveIntegerField(unique=True)
    name = models.CharField(max_length=60)
    min_xp = models.PositiveBigIntegerField(default=0)
    badge_image = models.ImageField(
        upload_to="gamification/levels/", null=True, blank=True
    )

    class Meta:
        verbose_name = "Level"
        verbose_name_plural = "Levels"
        ordering = ["number"]

    def __str__(self) -> str:
        return f"Level {self.number}: {self.name} ({self.min_xp} XP)"


class Badge(models.Model):
    """Earnable badge definition."""

    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True)
    description = models.TextField(blank=True, default="")
    image = models.ImageField(upload_to="gamification/badges/", null=True, blank=True)
    criteria = models.JSONField(
        default=dict, blank=True, help_text="Machine-readable criteria spec"
    )
    xp_value = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = "Badge"
        verbose_name_plural = "Badges"
        ordering = ["name"]

    def __str__(self) -> str:
        return f"{self.name} (+{self.xp_value} XP)"


class UserBadge(models.Model):
    """Association of a badge earned by a user."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="user_badges"
    )
    badge = models.ForeignKey(
        Badge, on_delete=models.CASCADE, related_name="user_badges"
    )
    earned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "User Badge"
        verbose_name_plural = "User Badges"
        unique_together = [("user", "badge")]
        ordering = ["-earned_at"]

    def __str__(self) -> str:
        return f"{self.user} earned {self.badge}"


class XPTransaction(models.Model):
    """Immutable XP credit/debit record."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="xp_transactions",
    )
    amount = models.IntegerField(help_text="Positive = gain, negative = loss")
    reason = models.CharField(max_length=200)
    source_type = models.CharField(max_length=50, blank=True, default="")
    source_id = models.BigIntegerField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "XP Transaction"
        verbose_name_plural = "XP Transactions"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        sign = "+" if self.amount >= 0 else ""
        return f"{sign}{self.amount} XP for {self.user} ({self.reason})"


class Streak(models.Model):
    """Daily activity streak tracker per user."""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="streak"
    )
    count = models.PositiveIntegerField(default=0)
    last_activity_date = models.DateField(null=True, blank=True)
    longest_streak = models.PositiveIntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Streak"
        verbose_name_plural = "Streaks"

    def __str__(self) -> str:
        return f"{self.user} streak={self.count}"


class Leaderboard(models.Model):
    """Leaderboard metadata — one per period/scope combination."""

    class PeriodType(models.TextChoices):
        DAILY = "daily", "Daily"
        WEEKLY = "weekly", "Weekly"
        MONTHLY = "monthly", "Monthly"
        ALL_TIME = "all_time", "All-Time"

    period_type = models.CharField(max_length=10, choices=PeriodType.choices)
    scope = models.CharField(max_length=50, default="global")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Leaderboard"
        verbose_name_plural = "Leaderboards"
        unique_together = [("period_type", "scope")]

    def __str__(self) -> str:
        return f"{self.period_type}/{self.scope}"


class LeaderboardEntry(models.Model):
    """Ranked user entry in a leaderboard snapshot."""

    leaderboard = models.ForeignKey(
        Leaderboard, on_delete=models.CASCADE, related_name="entries"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="leaderboard_entries",
    )
    rank = models.PositiveIntegerField()
    score = models.BigIntegerField()
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Leaderboard Entry"
        verbose_name_plural = "Leaderboard Entries"
        unique_together = [("leaderboard", "user")]
        ordering = ["leaderboard", "rank"]

    def __str__(self) -> str:
        return f"#{self.rank} {self.user} ({self.score} pts)"
