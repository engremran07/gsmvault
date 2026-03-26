"""
Generic Django Project Package
------------------------------

This file marks the directory as a Python package and exposes:
    • Stable project metadata (__version__, __author__, __description__)
    • Celery app instance for worker autodiscovery (required by django-celery-beat)
"""

# Celery bootstrap — required so Django finds the broker on startup and
# autodiscover_tasks() runs for every INSTALLED_APP.
from .celery import app as celery_app

__all__ = ["__author__", "__description__", "__version__", "celery_app"]

# ---------------------------------------------------------------------
# PROJECT METADATA (STATIC — SAFE — NO SIDE EFFECTS)
# ---------------------------------------------------------------------

# Semantic Version (bump per release/tag)
__version__ = "1.0.0"

# Generic, reusable project metadata
__author__ = "Application System"
__description__ = "Core initializer for the Django application package."
