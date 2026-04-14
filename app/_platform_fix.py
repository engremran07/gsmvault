"""Workaround for Python 3.13+ WMI deadlock on Windows.

Python 3.13 changed ``platform.system()`` to use WMI queries instead of
the Windows registry.  On some machines the WMI query
``_wmi.exec_query(...)`` blocks indefinitely, which freezes every library
that calls ``platform.system()`` at import time (Celery, Kombu, etc.).

This module caches the result of ``platform.system()`` using the safe
``sys.platform`` check, then monkey-patches ``platform.system`` and
``platform.uname`` so no WMI call is ever made.

**Import this module before any third-party library** (in manage.py,
wsgi.py, asgi.py, celery.py).

See: https://github.com/python/cpython/issues/114099
"""

from __future__ import annotations

import os
import platform
import sys

_NEED_PATCH = sys.platform == "win32" and sys.version_info >= (3, 13)

if _NEED_PATCH:
    # Build a static uname result using only safe, non-WMI sources.
    _system = "Windows"
    _node = os.environ.get("COMPUTERNAME", "localhost")
    _machine = os.environ.get("PROCESSOR_ARCHITECTURE", "AMD64")

    # Windows version from the *ver* command or kernel32 — no WMI needed.
    try:
        _release = sys.getwindowsversion().major  # type: ignore[attr-defined]
        _version_obj = sys.getwindowsversion()  # type: ignore[attr-defined]
        _version = f"{_version_obj.major}.{_version_obj.minor}.{_version_obj.build}"
    except AttributeError:
        _release = "11"
        _version = "10.0.0"

    _static_uname = platform.uname_result(
        system=_system,
        node=_node,
        release=str(_release),
        version=_version,
        machine=_machine,
    )

    platform.system = lambda: _system  # type: ignore[assignment]
    platform.uname = lambda: _static_uname  # type: ignore[assignment]
