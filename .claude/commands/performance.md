# /performance â€” Performance audit for Django ORM and views

Audit for N+1 query patterns, missing select_related/prefetch_related, unindexed filter fields, large unbounded querysets, and view-level inefficiencies.

## Scope

$ARGUMENTS

## Checklist

### Step 1: N+1 Query Detection

- [ ] Scan views and services for queryset loops that access related objects

- [ ] Identify FK/M2M access inside `for` loops without `select_related`/`prefetch_related`

- [ ] Check template `{{ obj.related.field }}` patterns against view querysets

- [ ] If $ARGUMENTS specifies an app, focus on `apps/$ARGUMENTS/`

### Step 2: select_related / prefetch_related

- [ ] Verify all views fetching related FK data use `select_related()`

- [ ] Verify all views fetching M2M or reverse FK data use `prefetch_related()`

- [ ] Check `services.py` queryset methods include appropriate prefetching

- [ ] Verify admin `list_display` with FK fields have `list_select_related`

### Step 3: Database Indexes

- [ ] Scan models for fields used in `filter()`, `order_by()`, `exclude()` without `db_index=True`

- [ ] Check compound lookups that would benefit from `Meta.indexes`

- [ ] Verify `unique_together` / `UniqueConstraint` where applicable

- [ ] Check for missing indexes on ForeignKey fields (Django auto-indexes, but verify)

### Step 4: Unbounded Querysets

- [ ] Scan for `.all()` without pagination or `[:limit]`

- [ ] Check views returning full querysets to templates without pagination

- [ ] Verify API endpoints use cursor/page pagination

- [ ] Look for `.count()` on large tables that could use caching

### Step 5: Caching Opportunities

- [ ] Identify expensive queries repeated across requests

- [ ] Check `apps.core.cache.DistributedCacheManager` usage for hot data

- [ ] Verify `SiteSettings` uses django-solo caching (singleton)

- [ ] Look for template fragments that could be cached

### Step 6: View-Level Issues

- [ ] Check for duplicate queries in same view (query once, pass to template)

- [ ] Verify `only()` / `defer()` on large models where only few fields needed

- [ ] Check file upload views for memory-efficient streaming

- [ ] Verify Celery offloads heavy computation from request cycle

### Step 7: Report

- [ ] List all N+1 patterns found with file:line references

- [ ] List missing indexes with the filter fields

- [ ] Estimate query reduction from fixes

- [ ] Prioritize by impact: high-traffic views first
