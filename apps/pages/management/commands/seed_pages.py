"""
Management command to seed default CMS pages (About, Terms, Privacy).

Creates pages only if they don't already exist (idempotent).
All content is editable afterwards from the Admin Panel → Pages section.

Usage:
    python manage.py seed_pages
    python manage.py seed_pages --publish   # also publish them immediately
"""

from __future__ import annotations

from django.core.management.base import BaseCommand

from apps.pages.models import Page

_DEFAULT_PAGES: list[dict[str, object]] = [
    {
        "slug": "about",
        "title": "About Us",
        "content": (
            "# About Us\n\n"
            "Welcome to GSMFWs — your trusted source for mobile firmware files.\n\n"
            "## Our Mission\n\n"
            "We provide a reliable, community-driven platform for downloading "
            "official and verified firmware for mobile devices worldwide.\n\n"
            "## What We Offer\n\n"
            "- **Official Firmware** — sourced directly from OEM servers\n"
            "- **Verified Files** — checked by our trusted tester programme\n"
            "- **Device Catalog** — comprehensive brand and model database\n"
            "- **Community** — active forums, bounty programme, and marketplace\n\n"
            "## Contact\n\n"
            "For enquiries, please reach out through our contact form or "
            "community channels."
        ),
        "content_format": "md",
        "access_level": "public",
        "include_in_sitemap": True,
        "changefreq": "monthly",
        "priority": 0.6,
        "seo_title": "About Us — GSMFWs",
        "seo_description": (
            "Learn about GSMFWs, the trusted platform for official mobile "
            "firmware downloads, device specifications, and community resources."
        ),
    },
    {
        "slug": "terms",
        "title": "Terms of Service",
        "content": (
            "# Terms of Service\n\n"
            "**Last updated:** Please update this date when editing.\n\n"
            "## 1. Acceptance of Terms\n\n"
            "By accessing or using this website, you agree to be bound by "
            "these Terms of Service.\n\n"
            "## 2. Use of Service\n\n"
            "You agree to use the service only for lawful purposes and in "
            "accordance with these terms.\n\n"
            "## 3. User Accounts\n\n"
            "You are responsible for maintaining the confidentiality of your "
            "account credentials.\n\n"
            "## 4. Intellectual Property\n\n"
            "All firmware files are the property of their respective "
            "manufacturers. We distribute them under applicable agreements.\n\n"
            "## 5. Limitation of Liability\n\n"
            "We are not liable for any damages arising from the use of "
            "downloaded firmware files. Use at your own risk.\n\n"
            "## 6. Changes to Terms\n\n"
            "We reserve the right to modify these terms at any time. "
            "Continued use constitutes acceptance of updated terms.\n\n"
            "---\n\n"
            "*Edit this page from the Admin Panel → Pages section.*"
        ),
        "content_format": "md",
        "access_level": "public",
        "include_in_sitemap": True,
        "changefreq": "monthly",
        "priority": 0.4,
        "seo_title": "Terms of Service — GSMFWs",
        "seo_description": (
            "Read the GSMFWs Terms of Service covering account usage, "
            "intellectual property, liability limitations, and more."
        ),
    },
    {
        "slug": "privacy",
        "title": "Privacy Policy",
        "content": (
            "# Privacy Policy\n\n"
            "**Last updated:** Please update this date when editing.\n\n"
            "## 1. Information We Collect\n\n"
            "We collect information you provide directly (account registration, "
            "profile data) and automatically (device info, usage analytics).\n\n"
            "## 2. Cookie Usage\n\n"
            "We use cookies for:\n"
            "- **Functional** — essential site operation (required)\n"
            "- **Analytics** — usage statistics and performance monitoring\n"
            "- **SEO & Performance** — search engine optimisation features\n"
            "- **Advertising** — personalised ads and affiliate tracking\n\n"
            "You can manage cookie preferences via our consent banner.\n\n"
            "## 3. How We Use Your Information\n\n"
            "- Provide and improve our services\n"
            "- Process downloads and manage quotas\n"
            "- Communicate account and service updates\n"
            "- Prevent fraud and enforce security policies\n\n"
            "## 4. Data Sharing\n\n"
            "We do not sell your personal data. We share data only with:\n"
            "- Service providers (hosting, analytics, CDN)\n"
            "- Law enforcement when legally required\n\n"
            "## 5. Data Retention\n\n"
            "We retain your data as long as your account is active or as "
            "needed to provide services.\n\n"
            "## 6. Your Rights\n\n"
            "You have the right to access, correct, or delete your personal "
            "data. Contact us to exercise these rights.\n\n"
            "## 7. Changes to This Policy\n\n"
            "We update this policy periodically. Check this page for the "
            "latest version.\n\n"
            "---\n\n"
            "*Edit this page from the Admin Panel → Pages section.*"
        ),
        "content_format": "md",
        "access_level": "public",
        "include_in_sitemap": True,
        "changefreq": "monthly",
        "priority": 0.4,
        "seo_title": "Privacy Policy — GSMFWs",
        "seo_description": (
            "GSMFWs Privacy Policy explaining data collection, cookie usage, "
            "data sharing practices, and your rights."
        ),
    },
]


class Command(BaseCommand):
    help = "Seed default CMS pages (About, Terms, Privacy). Idempotent."

    def add_arguments(self, parser):
        parser.add_argument(
            "--publish",
            action="store_true",
            help="Also set status to published (default: draft).",
        )

    def handle(self, *args, **options):
        publish = options["publish"]
        created_count = 0

        for page_data in _DEFAULT_PAGES:
            slug = page_data["slug"]
            if Page.objects.filter(slug=slug).exists():
                self.stdout.write(f"  Page '{slug}' already exists — skipping.")
                continue

            status = "published" if publish else "draft"
            Page.objects.create(status=status, **page_data)
            created_count += 1
            self.stdout.write(
                self.style.SUCCESS(f"  Created page '{slug}' ({status}).")
            )

        if created_count == 0:
            self.stdout.write("All default pages already exist. Nothing to do.")
        else:
            self.stdout.write(
                self.style.SUCCESS(f"\nDone — {created_count} page(s) created.")
            )
