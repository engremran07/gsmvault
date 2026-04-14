---
name: test-e2e-selenium
description: "End-to-end testing with Selenium/Playwright. Use when: testing full browser workflows, JavaScript interactions, form submissions, multi-page flows."
---

# End-to-End Browser Tests

## When to Use

- Testing full user workflows (registration → login → download)
- Verifying Alpine.js/HTMX interactions work in real browser
- Testing theme switching, modals, dropdowns
- Smoke testing critical paths before deployment

## Rules

### Selenium Setup

```python
import pytest
from django.contrib.staticfiles.testing import StaticLiveServerTestCase
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

@pytest.fixture(scope="session")
def browser():
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    driver = webdriver.Chrome(options=options)
    driver.set_window_size(1920, 1080)
    yield driver
    driver.quit()
```

### Playwright Setup (Preferred)

```python
import pytest

@pytest.fixture(scope="session")
def browser_context():
    from playwright.sync_api import sync_playwright
    pw = sync_playwright().start()
    browser = pw.chromium.launch(headless=True)
    context = browser.new_context(viewport={"width": 1920, "height": 1080})
    yield context
    context.close()
    browser.close()
    pw.stop()

@pytest.fixture
def page(browser_context):
    page = browser_context.new_page()
    yield page
    page.close()
```

### Testing Login Flow

```python
@pytest.mark.django_db
@pytest.mark.e2e
def test_login_flow(page, live_server):
    from tests.factories import UserFactory
    user = UserFactory()
    user.set_password("testpass123")
    user.save()

    page.goto(f"{live_server.url}/accounts/login/")
    page.fill('input[name="login"]', user.email)
    page.fill('input[name="password"]', "testpass123")
    page.click('button[type="submit"]')
    page.wait_for_url(f"{live_server.url}/**")
    assert "login" not in page.url.lower()
```

### Testing HTMX Interactions

```python
@pytest.mark.django_db
@pytest.mark.e2e
def test_htmx_search(page, live_server):
    from tests.factories import FirmwareFactory
    FirmwareFactory(version="Samsung-A52")
    page.goto(f"{live_server.url}/firmwares/")
    search_input = page.locator('input[name="q"]')
    search_input.fill("Samsung")
    # Wait for HTMX response
    page.wait_for_timeout(500)
    assert page.locator("text=Samsung-A52").is_visible()
```

### Testing Theme Switching

```python
@pytest.mark.e2e
def test_theme_toggle(page, live_server):
    page.goto(f"{live_server.url}/")
    # Click theme switcher
    theme_btn = page.locator('[data-theme-toggle]')
    if theme_btn.is_visible():
        theme_btn.click()
        theme = page.evaluate('document.documentElement.dataset.theme')
        assert theme in ("dark", "light", "contrast")
```

### Testing Alpine.js Components

```python
@pytest.mark.e2e
def test_modal_opens(page, live_server):
    page.goto(f"{live_server.url}/firmwares/")
    trigger = page.locator('[x-on\\:click*="modal"]').first
    if trigger.is_visible():
        trigger.click()
        page.wait_for_timeout(300)
        modal = page.locator('[x-show]').first
        assert modal.is_visible()
```

### Testing No Console Errors

```python
@pytest.mark.e2e
def test_no_js_errors(page, live_server):
    errors = []
    page.on("pageerror", lambda err: errors.append(str(err)))
    page.goto(f"{live_server.url}/")
    page.wait_for_load_state("networkidle")
    assert len(errors) == 0, f"JS errors: {errors}"
```

## Red Flags

- Running E2E tests in every CI run — too slow, run nightly
- Not using headless mode in CI — requires display server
- Hard-coded `time.sleep()` — use explicit waits (`wait_for_selector`)
- Not cleaning up browser instances — memory leaks in test suite
- Missing `@pytest.mark.e2e` marker — can't selectively skip

## Quality Gate

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
