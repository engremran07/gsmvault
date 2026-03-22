"""
apps.security — unified security layer.
Merges security_suite (config, WAF, rate limits) + security_events (audit events).
"""

from __future__ import annotations

from django.conf import settings
from django.db import models
from solo.models import SingletonModel


class SecurityConfig(SingletonModel):
    """Global DB-backed security controls."""

    mfa_enabled = models.BooleanField(default=True)
    mfa_policy = models.CharField(
        max_length=20,
        choices=[
            ("optional", "Optional"),
            ("required", "Required"),
            ("risk_based", "Risk-Based"),
        ],
        default="optional",
    )
    security_tier = models.CharField(
        max_length=16,
        choices=[("basic", "Basic"), ("standard", "Standard"), ("strict", "Strict")],
        default="standard",
    )
    login_risk_enabled = models.BooleanField(default=True)
    device_quota_enforcement = models.BooleanField(default=False)
    default_device_limit = models.PositiveIntegerField(default=5)
    default_device_window = models.CharField(
        max_length=4,
        choices=[("3m", "3 Months"), ("6m", "6 Months"), ("12m", "12 Months")],
        default="12m",
    )
    max_failed_logins = models.PositiveIntegerField(default=5)
    lockout_duration_minutes = models.PositiveIntegerField(default=15)
    require_email_verification = models.BooleanField(default=True)
    crawler_guard_enabled = models.BooleanField(default=True)
    # --- fields merged from security_suite ---
    devices_enabled = models.BooleanField(default=True)
    device_quota_enforcement_enabled = models.BooleanField(default=False)
    crawler_default_action = models.CharField(
        max_length=16,
        choices=[
            ("allow", "Allow"),
            ("throttle", "Throttle"),
            ("block", "Block"),
            ("challenge", "Challenge"),
        ],
        default="allow",
    )
    login_risk_policy = models.CharField(
        max_length=32,
        choices=[
            ("log_only", "Log Only"),
            ("mfa_if_high", "Require MFA if High Risk"),
            ("block_if_critical", "Block if Critical"),
        ],
        default="mfa_if_high",
    )
    csrf_trusted_origins = models.JSONField(default=list, blank=True)
    allowed_upload_extensions = models.JSONField(
        default=list,
        blank=True,
        help_text="Allowlist of file extensions for firmware uploads e.g. ['.zip', '.img']",
    )
    max_upload_size_mb = models.PositiveIntegerField(default=500)

    class Meta:
        verbose_name = "Security Config"

    def __str__(self) -> str:
        return "Security Config"


class SecurityEvent(models.Model):
    """Structured security event log — covers auth, WAF, downloads, admin actions."""

    class Severity(models.TextChoices):
        LOW = "low", "Low"
        MEDIUM = "medium", "Medium"
        HIGH = "high", "High"
        CRITICAL = "critical", "Critical"

    class EventType(models.TextChoices):
        LOGIN_FAIL = "login_fail", "Login Failure"
        LOGIN_SUCCESS = "login_success", "Login Success"
        LOGOUT = "logout", "Logout"
        PASSWORD_RESET = "password_reset", "Password Reset"
        MFA_FAIL = "mfa_fail", "MFA Failure"
        RATE_LIMITED = "rate_limited", "Rate Limited"
        IP_BLOCKED = "ip_blocked", "IP Blocked"
        CSRF_FAIL = "csrf_fail", "CSRF Failure"
        FILE_UPLOAD = "file_upload", "File Upload"
        ADMIN_ACTION = "admin_action", "Admin Action"
        SUSPICIOUS = "suspicious", "Suspicious Activity"
        BOT_DETECTED = "bot_detected", "Bot Detected"
        DOWNLOAD_ABUSE = "download_abuse", "Download Abuse"

    event_type = models.CharField(
        max_length=32, choices=EventType.choices, db_index=True
    )
    severity = models.CharField(
        max_length=10, choices=Severity.choices, default=Severity.LOW
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="security_events",
    )
    ip = models.GenericIPAddressField(null=True, blank=True, db_index=True)
    user_agent = models.CharField(max_length=512, blank=True, default="")
    path = models.CharField(max_length=512, blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Security Event"
        verbose_name_plural = "Security Events"
        indexes = [
            models.Index(
                fields=["event_type", "created_at"], name="sec_event_type_ts_idx"
            ),
            models.Index(fields=["ip", "created_at"], name="sec_event_ip_ts_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.event_type} [{self.severity}] @ {self.created_at}"


class RateLimitRule(models.Model):
    """Per-path rate limiting rules applied by SecurityMiddleware."""

    path_pattern = models.CharField(max_length=255, unique=True)
    limit = models.PositiveIntegerField(default=100, help_text="Requests per window")
    window_seconds = models.PositiveIntegerField(default=60)
    action = models.CharField(
        max_length=12,
        choices=[("throttle", "Throttle"), ("block", "Block"), ("log", "Log Only")],
        default="throttle",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Rate Limit Rule"
        verbose_name_plural = "Rate Limit Rules"
        ordering = ["path_pattern"]

    def __str__(self) -> str:
        return f"{self.path_pattern} — {self.limit}/{self.window_seconds}s"


class BlockedIP(models.Model):
    """IP addresses blocked by the security system."""

    ip = models.GenericIPAddressField(unique=True, db_index=True)
    reason = models.CharField(max_length=255, blank=True, default="")
    blocked_until = models.DateTimeField(
        null=True, blank=True, help_text="Null = permanent block"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="blocked_ips",
    )
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = "Blocked IP"
        verbose_name_plural = "Blocked IPs"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.ip} ({'permanent' if not self.blocked_until else str(self.blocked_until)})"


class CSPViolationReport(models.Model):
    """Content-Security-Policy browser violation reports."""

    document_uri = models.URLField(max_length=512, blank=True, default="")
    blocked_uri = models.URLField(max_length=512, blank=True, default="")
    violated_directive = models.CharField(max_length=100, blank=True, default="")
    ip = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=512, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "CSP Violation Report"
        verbose_name_plural = "CSP Violation Reports"
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"CSP: {self.violated_directive} @ {self.document_uri}"


# =============================================================================
# Crawler Guard — merged from apps.crawler_guard
# =============================================================================


class CrawlerRule(models.Model):
    """Bot/crawler path rules. Merged from apps.crawler_guard."""

    ACTION_CHOICES = [
        ("allow", "Allow"),
        ("throttle", "Throttle"),
        ("block", "Block"),
        ("challenge", "Challenge"),
    ]

    name = models.CharField(max_length=100, unique=True)
    path_pattern = models.CharField(
        max_length=255, help_text="fnmatch-style pattern e.g. /api/*"
    )
    requests_per_minute = models.PositiveIntegerField(default=60)
    action = models.CharField(max_length=20, choices=ACTION_CHOICES, default="allow")
    is_enabled = models.BooleanField(default=True)
    notes = models.TextField(blank=True, default="")
    priority = models.IntegerField(
        default=0, help_text="Higher value wins. Evaluated descending."
    )
    stop_processing = models.BooleanField(
        default=False,
        help_text="If matched and allowed, stop evaluating further rules.",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-priority", "name"]
        db_table = "crawler_guard_crawlerrule"
        verbose_name = "Crawler Rule"
        verbose_name_plural = "Crawler Rules"

    def __str__(self) -> str:
        return self.name


class CrawlerEvent(models.Model):
    """Bot/crawler event log. Merged from apps.crawler_guard."""

    ACTION_CHOICES = CrawlerRule.ACTION_CHOICES

    ip = models.CharField(max_length=45, db_index=True)
    device_identifier = models.CharField(
        max_length=64, blank=True, default="", db_index=True
    )
    path = models.CharField(max_length=255)
    rule_triggered = models.ForeignKey(
        CrawlerRule,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="events",
    )
    action_taken = models.CharField(
        max_length=20, choices=ACTION_CHOICES, default="allow"
    )
    user_agent = models.TextField(blank=True, default="")
    headers_hash = models.CharField(
        max_length=64, blank=True, default="", db_index=True
    )
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        db_table = "crawler_guard_crawlerevent"
        verbose_name = "Crawler Event"
        verbose_name_plural = "Crawler Events"
        indexes = [
            models.Index(fields=["ip", "created_at"], name="cg_ip_ts_idx"),
            models.Index(fields=["action_taken"], name="cg_action_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.ip} -> {self.action_taken}"


# Alias for admin views that reference the old CrawlerLog name
CrawlerLog = CrawlerEvent
