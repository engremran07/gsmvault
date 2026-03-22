"""Admin Suite view aggregator.

Explicitly imports all view modules and re-exports their public names.
"""

from __future__ import annotations

from . import views_shared as _shared

# Export core helpers for backward compatibility
__all__: list[str] = []
_shared_exports = (
    "logger",
    "_ADMIN_DISABLED",
    "_ADMIN_LOGIN_URL",
    "STAFF_ONLY",
    "_make_breadcrumb",
    "_render_admin",
)
for name in _shared_exports:
    globals()[name] = getattr(_shared, name)
    __all__.append(name)  # pyright: ignore[reportUnsupportedDunderAll]


def _reexport(module) -> None:  # noqa: ANN001
    exported = getattr(module, "__all__", None)
    if exported is None:
        exported = [n for n in dir(module) if not n.startswith("_")]
    for attr in exported:
        globals()[attr] = getattr(module, attr)
    __all__.extend(exported)


from . import (  # noqa: E402
    views_auth,  # noqa: E402
    views_content,  # noqa: E402
    views_distribution,  # noqa: E402
    views_extended,  # noqa: E402
    views_infrastructure,  # noqa: E402
    views_security,  # noqa: E402
    views_settings,  # noqa: E402
    views_users,  # noqa: E402
)

_reexport(views_auth)
_reexport(views_content)
_reexport(views_distribution)
_reexport(views_extended)
_reexport(views_infrastructure)
_reexport(views_security)
_reexport(views_settings)
_reexport(views_users)
