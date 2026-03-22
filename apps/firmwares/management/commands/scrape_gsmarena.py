"""
Management command to run the GSMArena scraper and ingest results.

Usage:
    python manage.py scrape_gsmarena --strategy brand_walk --sample-size 5
    python manage.py scrape_gsmarena --preset flagship_5g
    python manage.py scrape_gsmarena --preset full_catalogue --dry-run
"""

import logging

from django.core.management.base import BaseCommand

logger = logging.getLogger(__name__)

STRATEGIES = ["brand_walk", "search_targeted", "rumor_mill", "hybrid"]
PRESETS = [
    "full_catalogue",
    "sample_survey",
    "flagship_5g",
    "budget_global",
    "rumored_upcoming",
    "foldables",
    "top_brands_sampled",
    "android_flagship_snapdragon",
    "big_battery",
    "hybrid_5g_complete",
    "ios_all",
    "wearables",
]


class Command(BaseCommand):
    help = "Run the GSMArena scraper and ingest device specs into the database."

    def add_arguments(self, parser):
        parser.add_argument(
            "--strategy",
            choices=STRATEGIES,
            default="brand_walk",
            help="Crawl strategy (default: brand_walk)",
        )
        parser.add_argument(
            "--preset",
            choices=PRESETS,
            help="Use a preset crawl job configuration",
        )
        parser.add_argument(
            "--brand-limit",
            type=int,
            help="Max brands to scrape (brand_walk only)",
        )
        parser.add_argument(
            "--sample-size",
            type=int,
            help="Max devices per brand",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Log what would be ingested without writing to DB",
        )
        parser.add_argument(
            "--no-link",
            action="store_true",
            help="Skip auto-linking to local Device records",
        )

    def handle(self, *args, **options):
        from apps.firmwares.gsmarena_service import run_gsmarena_scrape

        strategy = options["strategy"]
        preset = options.get("preset")
        dry_run = options["dry_run"]

        self.stdout.write(
            self.style.NOTICE(
                f"Starting GSMArena scrape: strategy={strategy}, "
                f"preset={preset or 'none'}, dry_run={dry_run}"
            )
        )

        result = run_gsmarena_scrape(
            strategy=strategy,
            preset=preset,
            brand_limit=options.get("brand_limit"),
            sample_size=options.get("sample_size"),
            dry_run=dry_run,
            auto_link=not options["no_link"],
        )

        if result.get("error"):
            self.stderr.write(self.style.ERROR(f"Error: {result['error']}"))
            return

        self.stdout.write(
            self.style.SUCCESS(
                f"Sync run #{result.get('run_id')} completed: "
                f"checked={result.get('devices_checked', 0)}, "
                f"created={result.get('devices_created', 0)}, "
                f"updated={result.get('devices_updated', 0)}"
            )
        )

        errors = result.get("errors", [])
        if errors:
            self.stdout.write(self.style.WARNING(f"{len(errors)} errors recorded"))
            for err in errors[:10]:
                self.stdout.write(f"  - {err}")
