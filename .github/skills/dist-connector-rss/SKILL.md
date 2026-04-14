---
name: dist-connector-rss
description: "RSS/Atom feed distribution. Use when: generating RSS feeds, Atom feeds, JSON feeds, configuring feed entries from blog posts."
---

# RSS/Atom Feed Distribution

## When to Use
- Generating RSS 2.0 or Atom feeds for content syndication
- Configuring `channel="rss"`, `"atom"`, or `"json"` feed outputs
- Auto-updating feeds when new blog posts or firmware are published
- Serving feeds at standard URLs (`/feed/`, `/feed/atom/`, `/feed/json/`)

## Rules
- Channels: `rss`, `atom`, `json` — each generates different format
- RSS feeds served via Django's syndication framework (`django.contrib.syndication`)
- Feed entries auto-generated from published blog posts
- `DistributionSettings.distribution_enabled` must be True
- Feeds include: title, description, link, pubDate, guid, enclosure
- Cache feed output for 15 minutes to avoid DB load

## Patterns

### RSS Feed View
```python
# apps/distribution/feeds.py
from django.contrib.syndication.views import Feed
from django.utils.feedgenerator import Atom1Feed
from apps.blog.models import Post

class LatestPostsFeed(Feed):
    title = "Latest Blog Posts"
    link = "/blog/"
    description = "Recent blog posts and firmware news"

    def items(self):
        return Post.objects.filter(
            status="published"
        ).order_by("-published_at")[:20]

    def item_title(self, item: Post) -> str:
        return item.title

    def item_description(self, item: Post) -> str:
        return item.meta_description or item.excerpt or ""

    def item_pubdate(self, item: Post):
        return item.published_at

    def item_link(self, item: Post) -> str:
        return item.get_absolute_url()

class LatestPostsAtomFeed(LatestPostsFeed):
    feed_type = Atom1Feed
    subtitle = LatestPostsFeed.description
```

### URL Configuration
```python
# apps/distribution/urls.py
from apps.distribution.feeds import LatestPostsFeed, LatestPostsAtomFeed

urlpatterns = [
    path("feed/", LatestPostsFeed(), name="rss-feed"),
    path("feed/atom/", LatestPostsAtomFeed(), name="atom-feed"),
]
```

## Anti-Patterns
- Uncached feeds querying DB on every request
- No `guid` / unique identifier per entry — readers show duplicates
- Feed URLs not linked in `<head>` with `<link rel="alternate">`
- Returning 404 when feed is empty instead of empty valid XML

## Quality Gate
```powershell
& .\.venv\Scripts\python.exe -m ruff check . --fix
& .\.venv\Scripts\python.exe -m ruff format .
& .\.venv\Scripts\python.exe manage.py check --settings=app.settings_dev
```
