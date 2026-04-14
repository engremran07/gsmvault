---
name: regression-scraper-approval-monitor
description: >-
  Monitors scraper approval: auto-insert prevention.
  Use when: scraper audit, ingestion workflow check, auto-insert prevention scan.
---

# Regression Scraper Approval Monitor

Detects scraper approval workflow regressions: auto-inserting scraped data, bypassing IngestionJob review.

## Rules

1. Scraped firmware data must NEVER auto-insert into the database — auto-insert is CRITICAL.
2. All scraped data must create `IngestionJob` records with `status = "pending"`.
3. Admin approval is required before processing — no code path may bypass this.
4. Verify scraper code writes to `IngestionJob`, not directly to `Firmware` or related models.
5. Check that `ScraperRun` results always create `IngestionJob` records, never direct inserts.
6. Verify the admin approval UI (`Pending Approval` section) is accessible and functional.
7. Flag any direct `.create()` or `.save()` on `Firmware` models inside scraper code.

## Quality Gate (MANDATORY)

```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
