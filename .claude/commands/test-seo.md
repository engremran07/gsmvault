# /test-seo â€” Run SEO app test suite

Execute all tests for the SEO engine covering metadata, sitemaps, JSON-LD, redirects, internal linking, and AI automation.

## Scope

$ARGUMENTS

## Checklist

### Step 1: Run SEO Tests

- [ ] Full suite: `& .\.venv\Scripts\python.exe -m pytest apps/seo/ -v --settings=app.settings_dev`

- [ ] Specific test: `& .\.venv\Scripts\python.exe -m pytest apps/seo/ -v -k "$ARGUMENTS" --settings=app.settings_dev`

- [ ] With coverage: `& .\.venv\Scripts\python.exe -m pytest apps/seo/ -v --cov=apps/seo --cov-report=term-missing`

### Step 2: Verify Feature Coverage

- [ ] Metadata: title, description, canonical URL, Open Graph tags per page

- [ ] Sitemaps: XML generation, sitemap index, XSLT stylesheet, entry management

- [ ] JSON-LD: SchemaEntry creation, structured data validation, schema types

- [ ] Redirects: 301/302 redirect rules, chain detection, loop prevention

- [ ] Internal linking: LinkableEntity, LinkSuggestion, auto-linking engine

- [ ] SEO settings: 7 admin toggles, AI meta generation, auto-tags, auto-schema

- [ ] robots.txt: dynamic generation, disallow rules

- [ ] SeoAutomationSettings: AI-powered meta generation configuration

### Step 3: Validate SEO Output

- [ ] Verify sitemap XML is well-formed

- [ ] Check JSON-LD output validates against schema.org

- [ ] Confirm redirect rules don't create loops

- [ ] Run quality gate: `& .\.venv\Scripts\python.exe -m ruff check apps/seo/`
