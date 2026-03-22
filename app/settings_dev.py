"""
App Development Settings
Overrides production `settings.py` for safe local development.

- DEBUG mode enabled
- HTTPS redirection fully disabled
- No HSTS / CSRF secure cookie enforcement
- Console email backend
- Local-only allowed hosts
- Fast logging and hashing
- PostgreSQL database only (SQLite removed)
"""

from __future__ import annotations

import os
from pathlib import Path

# Load .env BEFORE setdefaults so .env values take precedence
try:
    from dotenv import load_dotenv  # type: ignore[import-untyped]

    load_dotenv()
except Exception:  # noqa: S110
    pass

# PostgreSQL is required - provide safe defaults for local development
os.environ.setdefault("DB_ENGINE", "django.db.backends.postgresql")
os.environ.setdefault("DB_USER", "postgres")
os.environ.setdefault("DB_HOST", "localhost")
os.environ.setdefault("DB_PORT", "5432")

from .settings import *  # import production defaults  # noqa: F403

# ============================================================
# Database - PostgreSQL Only
# ============================================================
# SQLite has been removed. PostgreSQL is required for development and production.
# Configure your PostgreSQL connection via environment variables:
# - DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT

# ============================================================
# Environment / Debug
# ============================================================
DEBUG = True
ENV = "development"
# Enable custom admin suite in development by default
ADMIN_SUITE_ENABLED = True

# Allow sync DB/session access in async dev server contexts (suppress SynchronousOnlyOperation)
os.environ.setdefault("DJANGO_ALLOW_ASYNC_UNSAFE", "true")

ACCOUNT_AUTHENTICATED_LOGIN_REDIRECTS = False

ALLOWED_HOSTS = ["127.0.0.1", "localhost", "0.0.0.0", "testserver"]  # noqa: S104
SITE_ID = 1

# Required for django.template.context_processors.debug to expose 'debug' in templates
INTERNAL_IPS = ["127.0.0.1"]


# ============================================================
# Security Overrides (force HTTP)
# ============================================================
# Completely disable all HTTPS-related enforcement for dev
SECURE_SSL_REDIRECT = False
SECURE_HSTS_SECONDS = 0
SECURE_HSTS_INCLUDE_SUBDOMAINS = False
SECURE_HSTS_PRELOAD = False
SECURE_BROWSER_XSS_FILTER = False
SECURE_CONTENT_TYPE_NOSNIFF = False

SESSION_COOKIE_SECURE = False
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"
SESSION_COOKIE_AGE = 1209600  # 14 days
SESSION_SAVE_EVERY_REQUEST = False

CSRF_COOKIE_SECURE = False
CSRF_COOKIE_HTTPONLY = False
CSRF_COOKIE_SAMESITE = "Lax"

# Dev: do not trust X-Forwarded-Proto by default
SECURE_PROXY_SSL_HEADER = None

# Ensure SslToggleMiddleware never forces HTTPS in dev
os.environ["FORCE_HTTPS_DEV_OVERRIDE"] = "0"
MIDDLEWARE = [
    mw
    for mw in MIDDLEWARE  # noqa: F405
    if mw != "apps.core.middleware.ssl_toggle.SslToggleMiddleware"
]


# ============================================================
# CSRF & Trusted Origins
# ============================================================
CSRF_TRUSTED_ORIGINS = [
    "http://127.0.0.1:8000",
    "http://localhost:8000",
]

# When already authenticated, redirect away from login/signup to the dashboard
ACCOUNT_AUTHENTICATED_LOGIN_REDIRECTS = True


# ============================================================
# Local SSL Certificate (optional, cross-platform)
# ============================================================
# Only used if you intentionally run dev server with TLS.
# Override via env if you want a custom location.
CERT_DIR = Path(os.environ.get("GSM_DEV_CERT_DIR", Path.home() / ".gsm_certs"))
SSL_CERT_FILE = CERT_DIR / "localhost.pem"
SSL_KEY_FILE = CERT_DIR / "localhost-key.pem"

if SSL_CERT_FILE.exists() and SSL_KEY_FILE.exists():
    print(f"[DEV] Local HTTPS certs available: {SSL_CERT_FILE.name}")
else:
    print("[DEV] No local certs found - running HTTP-only")


# ============================================================
# Logging Configuration
# ============================================================
LOGGING["root"]["level"] = "DEBUG"  # noqa: F405
LOGGING["loggers"]["django"]["level"] = "DEBUG"  # noqa: F405

for logger_name in ("apps.users", "apps.core", "apps.consent", "apps.site_settings"):
    LOGGING["loggers"].setdefault(  # noqa: F405
        logger_name,
        {
            "handlers": ["console"],
            "level": "DEBUG",
            "propagate": False,
        },
    )


# ============================================================
# Email Backend (safe console)
# ============================================================
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"
DEFAULT_FROM_EMAIL = "dev@localhost"


# ============================================================
# Caching (local memory)
# ============================================================
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "TIMEOUT": 300,
    }
}

# ============================================================
# Security headers (Content-Security-Policy extras)
# ============================================================
SECURITY_SCRIPT_SRC_EXTRA = (
    "'unsafe-eval'",  # Required: Alpine.js CDN + Tailwind Browser CDN use eval()
    "https://cdn.jsdelivr.net",
    "https://cdnjs.cloudflare.com",
    "https://unpkg.com",
)
SECURITY_STYLE_SRC_EXTRA = (
    "https://cdn.jsdelivr.net",
    "https://cdnjs.cloudflare.com",
    "https://unpkg.com",
    "https://fonts.googleapis.com",
)
SECURITY_CONNECT_SRC_EXTRA = (
    "https://cdn.jsdelivr.net",  # Source maps for CDN scripts (dev only)
    "https://fonts.googleapis.com",
    "https://fonts.gstatic.com",
)
SECURITY_FONT_SRC_EXTRA = ("https://fonts.gstatic.com",)
SECURITY_FRAME_SRC_EXTRA = (
    "https://www.youtube.com/",
    "https://www.youtube-nocookie.com/",
    "https://player.vimeo.com/",
)

# Relax COEP/CORP in dev — CDN resources need cross-origin access
SECURITY_COEP_VALUE = "unsafe-none"
SECURITY_CORP_VALUE = "cross-origin"


# ============================================================
# Password Hashers (secure, still suitable for development)
# ============================================================
PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.PBKDF2PasswordHasher",
]

# ============================================================
# Admin suite redirects (dev parity with production)
# ============================================================
LOGOUT_REDIRECT_URL = "admin_suite:admin_suite_login"


# ============================================================
# Final notice
# ============================================================
print("[DEV] App Development Settings Loaded (HTTP-only, DEBUG=True)")
