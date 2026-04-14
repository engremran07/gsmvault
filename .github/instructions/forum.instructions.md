---
applyTo: 'apps/forum/**'
---

# Forum App Instructions

## Overview

`apps.forum` is a full-featured community forum inspired by 4PDA, vBulletin, and Discourse. Self-contained Django app with 30+ models, a services layer, HTMX fragments, and Alpine.js interactivity.

## Architecture Rule: Business Logic in `services.py`

ALL business logic lives in `apps/forum/services.py`. Views are thin orchestrators — they call service functions and render templates.

Key service functions:
- `create_topic()`, `create_reply()`, `edit_reply()`
- `toggle_like()`, `toggle_favorite()`, `toggle_useful_post()`
- `create_poll()`, `cast_vote()`
- `update_wiki_header()`, `add_faq_entry()`, `add_changelog_entry()`
- `search_topics()`, `get_online_users()`, `get_forum_stats()`
- `get_trending_topics()`, `get_recent_topics()`, `get_latest_replies()`
- `evaluate_trust_level()`, `move_topic()`, `merge_topics()`

## Topic Types

```python
class TopicType(models.TextChoices):
    DISCUSSION = "discussion", "Discussion"
    FIRMWARE = "firmware", "Firmware"
    FAQ = "faq", "FAQ"
    GUIDE = "guide", "Guide"
    NEWS = "news", "News"
    REVIEW = "review", "Review"
    BUG_REPORT = "bug_report", "Bug Report"
```

## Core Models

| Model | Purpose |
|---|---|
| `ForumCategory` | Hierarchical categories (parent/child) with icons, colours, privacy |
| `ForumTopic` | Discussion threads with prefix, type, wiki header, device link |
| `ForumReply` | Replies with Markdown, @mentions, edit history |
| `ForumPoll` / `PollChoice` / `PollVote` | Polls (single/multiple, secret ballot) |
| `ForumReaction` / `ReplyReaction` | Configurable reactions (Like, Love, Insightful, etc.) |
| `ForumTrustLevel` | Auto-promotion criteria |
| `ForumUserProfile` | Per-user stats, reputation, signatures, custom titles |

## 4PDA-Specific Features

### Wiki Headers (Шапка)

Collaboratively editable header post on each topic:

```python
# Service function
def update_wiki_header(topic, user, content):
    # Create history entry before update
    ForumWikiHeaderHistory.objects.create(
        topic=topic,
        content=topic.wiki_header,
        edited_by=user,
    )
    topic.wiki_header = content
    topic.save(update_fields=["wiki_header"])
```

### Changelogs

Per-topic version timeline:

```python
ForumChangelog.objects.create(
    topic=topic,
    version="v1.2.3",
    content="Fixed boot loop on SM-G998B",
    release_date=date.today(),
    author=user,
)
```

### FAQ Entries

Per-topic FAQ sidebar linking to specific replies:

```python
ForumFAQEntry.objects.create(
    topic=topic,
    question="How do I flash this firmware?",
    reply=answer_reply,  # FK to the reply that answers this
    order=1,
)
```

### Useful Post Marks

Community-driven answer highlighting with reputation rewards:

```python
# Service function
def toggle_useful_post(reply, user):
    useful, created = ForumUsefulPost.objects.get_or_create(
        reply=reply, marked_by=user,
    )
    if not created:
        useful.delete()
    return created  # True if marked, False if unmarked
```

## Device Linking

Topics can be linked to firmware device models:

```python
class ForumTopic(TimestampedModel):
    device = models.ForeignKey(
        "firmwares.Model",
        null=True, blank=True,
        on_delete=models.SET_NULL,
        related_name="forum_topics",
    )
```

## Trust Levels

Discourse-style auto-promotion based on activity:

```python
class ForumTrustLevel(TimestampedModel):
    level = models.IntegerField(unique=True)    # 0, 1, 2, 3, 4
    name = models.CharField(max_length=50)       # "New", "Basic", "Member", "Regular", "Leader"
    min_topics_read = models.IntegerField()
    min_replies_created = models.IntegerField()
    min_days_active = models.IntegerField()
    min_likes_received = models.IntegerField()
    can_create_polls = models.BooleanField()
    can_edit_wiki = models.BooleanField()
    can_flag_posts = models.BooleanField()
```

## Moderation Tools

| Model | Purpose |
|---|---|
| `ForumWarning` | User warnings with reason and expiry |
| `ForumIPBan` | IP-based forum bans |
| `ForumFlag` | Content flagging for moderator review |
| `ForumTopicMoveLog` | Audit trail for topic moves between categories |
| `ForumTopicMergeLog` | Audit trail for merged topics |

## URL Patterns

All under `forum:` namespace:
- Category: `c/<slug>/`
- Topic: `t/<pk>/<slug>/`
- Search: `search/`
- Private messages: `messages/`
- Leaderboard: `leaderboard/`
- Online users: `whos-online/`

## Templates

- `forum_index.html` — Landing page with stats, search, trending, categories
- `category_detail.html` — Topic listing with filters
- `topic_detail.html` — Full topic view (wiki header, polls, replies, reactions)
- `fragments/` — 15+ HTMX fragments for partial updates

## HTMX Fragments

Fragments in `templates/forum/fragments/` are standalone snippets — they must NOT use `{% extends %}`:

```html
{# fragments/reply_item.html — CORRECT #}
<div class="reply-item" id="reply-{{ reply.pk }}">
  <div class="reply-content">{{ reply.content }}</div>
  <div class="reply-actions">
    {% include "components/_badge.html" with text=reply.author.username %}
  </div>
</div>
```

## Seed Command

```powershell
& .\.venv\Scripts\python.exe manage.py seed_forum --settings=app.settings_dev
```

Seeds 8 users, 12 categories, 10 topics, 23 replies, polls, tags, wiki headers, changelogs, FAQ entries, online users.
