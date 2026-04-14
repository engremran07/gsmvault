---
name: views-mixins
description: "View mixins: LoginRequiredMixin, UserPassesTestMixin, custom mixins. Use when: composing CBV behavior, access control, shared context, HTMX detection reuse."
---

# View Mixins

## When to Use
- Adding authentication/authorization to class-based views
- Sharing common context data across multiple views
- HTMX request detection across many views
- Staff-only access patterns

## Rules
- Mixins go BEFORE the base view in MRO: `class MyView(LoginRequiredMixin, ListView)`
- Custom mixins go in the app's `views.py` or a shared `apps/core/mixins.py`
- `test_func()` in `UserPassesTestMixin` MUST return `bool`
- Use `getattr(request.user, "is_staff", False)` for anonymous-safe staff checks
- Never put business logic in mixins — only view-level concerns

## Patterns

### LoginRequired + Staff Check
```python
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin

class StaffRequiredMixin(LoginRequiredMixin, UserPassesTestMixin):
    """Reusable mixin: requires authenticated staff user."""
    def test_func(self) -> bool:
        return getattr(self.request.user, "is_staff", False)

# Usage:
class AdminDashboardView(StaffRequiredMixin, TemplateView):
    template_name = "admin/dashboard.html"
```

### HTMX Template Mixin
```python
class HtmxTemplateMixin:
    """Switches template for HTMX requests (renders fragment instead of full page)."""
    htmx_template_name: str = ""

    def get_template_names(self) -> list[str]:
        if self.request.headers.get("HX-Request") and self.htmx_template_name:
            return [self.htmx_template_name]
        return super().get_template_names()  # type: ignore[misc]

# Usage:
class FirmwareListView(HtmxTemplateMixin, ListView):
    template_name = "firmwares/list.html"
    htmx_template_name = "firmwares/fragments/list.html"
    model = Firmware
    paginate_by = 20
```

### Ownership Mixin
```python
class OwnerRequiredMixin(LoginRequiredMixin, UserPassesTestMixin):
    """Ensures the current user owns the object or is staff."""
    owner_field: str = "user"

    def test_func(self) -> bool:
        obj = self.get_object()
        owner = getattr(obj, self.owner_field, None)
        return owner == self.request.user or getattr(self.request.user, "is_staff", False)

# Usage:
class EditProfileView(OwnerRequiredMixin, UpdateView):
    model = UserProfile
    owner_field = "user"
    form_class = ProfileForm
```

### Context Injection Mixin
```python
class BreadcrumbMixin:
    """Adds breadcrumb data to template context."""
    breadcrumbs: list[tuple[str, str]] = []

    def get_context_data(self, **kwargs: Any) -> dict[str, Any]:
        context = super().get_context_data(**kwargs)  # type: ignore[misc]
        context["breadcrumbs"] = self.breadcrumbs
        return context

# Usage:
class FirmwareDetailView(BreadcrumbMixin, DetailView):
    model = Firmware
    breadcrumbs = [("Home", "/"), ("Firmwares", "/firmwares/")]
```

### Composing Multiple Mixins
```python
class FirmwareCreateView(
    LoginRequiredMixin,       # 1. Must be logged in
    UserPassesTestMixin,      # 2. Must pass test
    HtmxTemplateMixin,       # 3. HTMX fragment support
    BreadcrumbMixin,          # 4. Breadcrumbs in context
    CreateView,               # 5. Base view LAST
):
    model = Firmware
    form_class = FirmwareForm
    template_name = "firmwares/create.html"
    htmx_template_name = "firmwares/fragments/create_form.html"
    breadcrumbs = [("Home", "/"), ("Firmwares", "/firmwares/")]

    def test_func(self) -> bool:
        return getattr(self.request.user, "is_staff", False)
```

### MRO Order Rule
```
class MyView(
    AuthMixin,          # Access control first
    PermissionMixin,    # Then permissions
    UtilityMixin,       # Then utilities
    ContextMixin,       # Then context enrichment
    BaseView,           # Base view ALWAYS LAST
):
```

## Anti-Patterns
- Base view before mixins in MRO — mixins must come first
- Business logic in mixins — only view concerns (auth, context, template selection)
- Redundant `login_required` decorator on CBV with `LoginRequiredMixin` — pick one
- Missing `getattr` safe pattern for `is_staff` — `request.user.is_staff` crashes for anonymous
- Deep mixin hierarchies (5+) — consider function-based views instead

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```

## References
- [Django Auth Mixins](https://docs.djangoproject.com/en/5.2/topics/auth/default/#the-loginrequiredmixin-mixin)
