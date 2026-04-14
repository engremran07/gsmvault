---
paths: ["apps/*/signals.py"]
---

# Signals Layer Rules

Django signals and the EventBus provide decoupled communication between apps without violating app boundary rules.

## Signal Definition

- Platform-level signals are defined in `apps.core.signals` (e.g., `firmware_uploaded`, `firmware_download_ready`, `storage_quota_exhausted`).
- App-specific signals are defined in each app's `signals.py`.
- Use `django.dispatch.Signal()` for custom signals.
- Document signal arguments in a docstring at the definition site.

## Signal Registration

- ALWAYS register signal handlers in the app's `AppConfig.ready()` method in `apps.py`:
  ```python
  def ready(self) -> None:
      import apps.myapp.signals  # noqa: F401
  ```
- NEVER import signal handlers at module level in `models.py` or `__init__.py` — this causes circular imports.
- Use `@receiver(signal, sender=Model)` decorator for handler registration.
- ALWAYS specify `sender` when connecting to model signals to avoid catching unrelated models.

## Handler Rules

- Signal handlers MUST be lightweight — no heavy queries, no long-running I/O.
- For heavy work, dispatch to a Celery task from the handler:
  ```python
  @receiver(post_save, sender=Firmware)
  def on_firmware_saved(sender, instance, created, **kwargs):
      if created:
          process_firmware.delay(instance.pk)
  ```
- Handlers MUST NOT raise exceptions that could break the sender's transaction.
- Wrap handler bodies in `try/except` and log errors — NEVER let a handler crash the request.
- NEVER modify the sender's instance in a `post_save` handler without `update_fields` guard (infinite loop risk).

## EventBus for Cross-App Communication

- Use `apps.core.events.EventBus` for decoupled cross-app events instead of direct imports.
- Event types are defined in `apps.core.events.EventTypes`.
- Subscribe with `event_bus.subscribe(EventTypes.FIRMWARE_UPLOADED, handler)`.
- Emit with `event_bus.emit(EventTypes.FIRMWARE_UPLOADED, data={"pk": pk})`.
- NEVER import another app's models directly in `signals.py` — use EventBus or `sender` param.

## Testing

- Test signal handlers by triggering the signal and asserting side effects.
- Use `Signal.disconnect()` in tests to isolate handler behavior.
- Mock Celery tasks dispatched from signal handlers to avoid async side effects in tests.
