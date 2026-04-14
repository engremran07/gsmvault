---
name: test-model-signals
description: "Signal handler tests: mocking signals, verifying callbacks. Use when: testing post_save, pre_delete, custom signals, signal handler side effects."
---

# Model Signal Tests

## When to Use

- Verifying signal handlers fire correctly
- Testing side effects of signal handlers
- Mocking signals to isolate test units
- Testing custom signals from `apps.core.signals`

## Rules

### Testing Signal Fires

```python
import pytest
from unittest.mock import patch

@pytest.mark.django_db
def test_post_save_signal_fires():
    from tests.factories import FirmwareFactory
    with patch("apps.firmwares.signals.handle_firmware_created") as mock_handler:
        FirmwareFactory()
        assert mock_handler.called

@pytest.mark.django_db
def test_signal_receives_correct_instance():
    from tests.factories import FirmwareFactory
    with patch("apps.firmwares.signals.handle_firmware_created") as mock_handler:
        fw = FirmwareFactory(version="1.0.0")
        mock_handler.assert_called_once()
        call_kwargs = mock_handler.call_args[1]
        assert call_kwargs["instance"].version == "1.0.0"
```

### Disconnecting Signals for Isolation

```python
from django.db.models.signals import post_save

@pytest.fixture
def no_signals():
    """Temporarily disconnect all post_save signals."""
    receivers = post_save.receivers[:]
    post_save.receivers = []
    yield
    post_save.receivers = receivers

@pytest.mark.django_db
def test_model_without_signals(no_signals):
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory()  # No signal side effects
    assert fw.pk is not None
```

### factory_boy's mute_signals

```python
import factory

@factory.django.mute_signals(post_save)
@pytest.mark.django_db
def test_isolated_from_signals():
    from tests.factories import FirmwareFactory
    fw = FirmwareFactory()
    # Signal handlers don't fire during this test
```

### Testing Custom Signals

```python
@pytest.mark.django_db
def test_custom_signal_emission():
    from apps.core.signals import firmware_uploaded
    handler = pytest.Mock()
    firmware_uploaded.connect(handler)
    try:
        from tests.factories import FirmwareFactory
        fw = FirmwareFactory()
        firmware_uploaded.send(sender=fw.__class__, instance=fw)
        handler.assert_called_once()
    finally:
        firmware_uploaded.disconnect(handler)
```

### Testing EventBus Events

```python
@pytest.mark.django_db
def test_event_bus_emission():
    from apps.core.events.bus import event_bus, EventTypes
    from unittest.mock import Mock
    handler = Mock()
    event_bus.subscribe(EventTypes.FIRMWARE_UPLOADED, handler)
    try:
        event_bus.publish(EventTypes.FIRMWARE_UPLOADED, firmware_id=1)
        handler.assert_called_once()
    finally:
        event_bus.unsubscribe(EventTypes.FIRMWARE_UPLOADED, handler)
```

## Red Flags

- Not disconnecting signals after tests — leaks handlers to other tests
- Testing signal handler logic via model creation — test the handler directly
- Missing `try/finally` on connect/disconnect — handler leaks on failure
- Mocking the wrong signal path — check `apps.py` `ready()` for registration

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
