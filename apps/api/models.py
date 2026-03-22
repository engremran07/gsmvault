"""apps.api — API keys, endpoint catalog, usage log."""

from __future__ import annotations

import hashlib
import secrets

from django.conf import settings
from django.db import models


def _gen_key_prefix() -> str:
    return "sp_" + secrets.token_urlsafe(6)


def _gen_key_raw() -> str:
    return secrets.token_urlsafe(40)


class APIKey(models.Model):
    """Per-user API key for programmatic access."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="api_keys"
    )
    name = models.CharField(max_length=100)
    key_prefix = models.CharField(
        max_length=20, unique=True, default=_gen_key_prefix, db_index=True
    )
    key_hash = models.CharField(max_length=128, unique=True)
    scopes = models.JSONField(
        default=list,
        blank=True,
        help_text="List of scope strings e.g. ['read:firmware', 'write:firmware']",
    )
    is_active = models.BooleanField(default=True, db_index=True)
    last_used_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "API Key"
        verbose_name_plural = "API Keys"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.name} ({self.key_prefix}…)"

    @classmethod
    def create_key(
        cls, user, name: str, scopes: list[str] | None = None
    ) -> tuple[APIKey, str]:
        """Create an API key and return (instance, raw_key). Raw key is only visible once."""
        raw = _gen_raw = _gen_key_raw()
        hashed = hashlib.sha256(raw.encode()).hexdigest()
        instance = cls.objects.create(
            user=user,
            name=name,
            key_hash=hashed,
            scopes=scopes or [],
        )
        return instance, raw


class APIEndpoint(models.Model):
    """Catalog of known API endpoints — used for docs + rate limiting."""

    path = models.CharField(max_length=255, db_index=True)
    method = models.CharField(
        max_length=10,
        choices=[
            ("GET", "GET"),
            ("POST", "POST"),
            ("PUT", "PUT"),
            ("PATCH", "PATCH"),
            ("DELETE", "DELETE"),
        ],
        default="GET",
    )
    description = models.TextField(blank=True, default="")
    rate_limit = models.PositiveIntegerField(
        default=100, help_text="Requests per minute"
    )
    is_deprecated = models.BooleanField(default=False)
    deprecated_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "API Endpoint"
        verbose_name_plural = "API Endpoints"
        unique_together = [("path", "method")]
        ordering = ["path", "method"]

    def __str__(self) -> str:
        flag = " [deprecated]" if self.is_deprecated else ""
        return f"{self.method} {self.path}{flag}"


class APIUsageLog(models.Model):
    """Per-request API usage log for analytics and billing."""

    api_key = models.ForeignKey(
        APIKey,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="usage_logs",
    )
    endpoint = models.CharField(max_length=255, db_index=True)
    method = models.CharField(max_length=10, default="GET")
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)
    response_code = models.PositiveSmallIntegerField()
    latency_ms = models.PositiveIntegerField(default=0)
    ip = models.GenericIPAddressField(null=True, blank=True)

    class Meta:
        verbose_name = "API Usage Log"
        verbose_name_plural = "API Usage Logs"
        ordering = ["-timestamp"]
        indexes = [
            models.Index(fields=["api_key", "timestamp"], name="apilog_key_ts_idx"),
        ]

    def __str__(self) -> str:
        return f"[{self.response_code}] {self.method} {self.endpoint}"
