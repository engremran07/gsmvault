"""apps.forum.event_handlers — Cross-app event handlers for forum integration.

Responds to blog publish signals to auto-create linked ForumTopic discussions.
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)


def handle_post_published(sender: type, post: object, **kwargs: object) -> None:
    """Create a ForumTopic for a newly published blog post (if applicable).

    Conditions:
    - ``post.allow_comments`` is True
    - ``post.forum_topic_id`` is None (not already linked)
    """
    from apps.blog.models import Post

    if not isinstance(post, Post):
        return
    if not post.allow_comments or post.forum_topic_id is not None:  # type: ignore[attr-defined]
        return

    try:
        from apps.forum.models import ForumCategory
        from apps.forum.services import create_topic

        # Pick category: match brand_link if post has firmware_brand, else "General Discussion"
        category = None
        if post.firmware_brand_id:  # type: ignore[attr-defined]
            category = ForumCategory.objects.filter(
                brand_link_id=post.firmware_brand_id  # type: ignore[attr-defined]
            ).first()
        if category is None:
            category = ForumCategory.objects.filter(slug="general").first()
        if category is None:
            logger.warning(
                "No forum category found for blog post %s — skipping topic creation",
                post.pk,
            )
            return

        summary = post.summary or post.title
        content = (
            f"**Blog discussion:** [{post.title}]({post.get_absolute_url()})\n\n"
            f"{summary}"
        )
        topic = create_topic(
            user=post.author,
            category=category,
            title=post.title,
            content=content,
        )
        # Update FK without re-triggering post_save
        Post.objects.filter(pk=post.pk).update(forum_topic=topic)
        logger.info("Auto-created forum topic %s for blog post %s", topic.pk, post.pk)
    except Exception:
        logger.exception("Failed to create forum topic for blog post %s", post.pk)
