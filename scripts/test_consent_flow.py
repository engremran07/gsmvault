"""One-shot consent flow integration test — run with Django test runner."""

import json
import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "app.settings_dev")

import django  # noqa: E402

django.setup()

from django.test import Client  # noqa: E402

from apps.consent.models import (  # noqa: E402
    ConsentDecision,
    ConsentEvent,
    ConsentPolicy,
)


def main() -> None:
    # Clear old test data
    ConsentEvent.objects.all().delete()
    ConsentDecision.objects.all().delete()

    c = Client(enforce_csrf_checks=False)

    # 1. Test accept_all
    print("=== accept_all ===")
    resp = c.post("/consent/accept_all/", HTTP_REFERER="http://localhost:8000/")
    print(f"Status: {resp.status_code}")
    print(f"Location: {resp.get('Location', 'N/A')}")
    cookie = resp.cookies.get("consent_status")
    print(f"Cookie set: {bool(cookie)}")
    if cookie:
        print(f"Cookie value: {cookie.value}")
        parsed = json.loads(cookie.value)
        print(f"Cookie parsed: {parsed}")
    d = ConsentDecision.objects.last()
    print(f"DB Decision saved: {bool(d)}")
    if d:
        print(f"  categories: {d.categories}")
        print(f"  session_id: {bool(d.session_id)}")
        print(f"  ip_hash: {bool(d.ip_hash)}")
    e = ConsentEvent.objects.last()
    print(f"DB Event saved: {bool(e)}")
    if e:
        print(f"  event_type: {e.event_type}")
        print(f"  categories: {e.categories}")

    # 2. Test reject_all
    print()
    print("=== reject_all ===")
    resp2 = c.post("/consent/reject_all/", HTTP_REFERER="http://localhost:8000/test/")
    print(f"Status: {resp2.status_code}")
    print(f"Location: {resp2.get('Location', 'N/A')}")
    cookie2 = resp2.cookies.get("consent_status")
    print(f"Cookie set: {bool(cookie2)}")
    if cookie2:
        print(f"Cookie value: {cookie2.value}")
        parsed2 = json.loads(cookie2.value)
        print(f"Cookie parsed: {parsed2}")
    d2 = ConsentDecision.objects.order_by("-pk").first()
    print(f"DB Decision saved: {bool(d2)}")
    if d2:
        print(f"  categories: {d2.categories}")
    e2 = ConsentEvent.objects.order_by("-pk").first()
    print(f"DB Event saved: {bool(e2)}")
    if e2:
        print(f"  event_type: {e2.event_type}")

    # 3. Test granular accept
    print()
    print("=== accept (granular) ===")
    body = json.dumps(
        {"functional": True, "analytics": True, "seo": False, "ads": False}
    )
    resp3 = c.post(
        "/consent/accept/",
        data=body,
        content_type="application/json",
        HTTP_REFERER="http://localhost:8000/",
    )
    print(f"Status: {resp3.status_code}")
    print(f"Location: {resp3.get('Location', 'N/A')}")
    cookie3 = resp3.cookies.get("consent_status")
    print(f"Cookie set: {bool(cookie3)}")
    if cookie3:
        print(f"Cookie value: {cookie3.value}")
        parsed3 = json.loads(cookie3.value)
        print(f"Cookie parsed: {parsed3}")
    d3 = ConsentDecision.objects.order_by("-pk").first()
    print(f"DB Decision saved: {bool(d3)}")
    if d3:
        print(f"  categories: {d3.categories}")
    e3 = ConsentEvent.objects.order_by("-pk").first()
    print(f"DB Event saved: {bool(e3)}")
    if e3:
        print(f"  event_type: {e3.event_type}")

    # Summary
    print()
    print("=== SUMMARY ===")
    print(f"Total Decisions: {ConsentDecision.objects.count()}")
    print(f"Total Events: {ConsentEvent.objects.count()}")
    policies = ConsentPolicy.objects.filter(is_active=True)
    print(f"Active Policies: {policies.count()}")


if __name__ == "__main__":
    main()
