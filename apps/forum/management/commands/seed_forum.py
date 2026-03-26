"""Seed realistic forum data for visual smoke testing."""

from __future__ import annotations

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.forum import services
from apps.forum.models import (
    ForumCategory,
    ForumChangelog,
    ForumFAQEntry,
    ForumOnlineUser,
    ForumPoll,
    ForumPollChoice,
    ForumReaction,
    ForumReply,
    ForumTopic,
    ForumTopicPrefix,
    ForumTopicTag,
    ForumTrustLevel,
    ForumUserProfile,
    TopicType,
)

User = get_user_model()


class Command(BaseCommand):
    help = "Seed the forum with realistic test data for visual smoke testing."

    def handle(self, *args: object, **kwargs: object) -> None:
        self.stdout.write("Seeding forum data…")

        # --- Users ---
        users = []
        user_data = [
            ("admin_sam", "sam@gsmvault.dev", True),
            ("flash_master", "flash@gsmvault.dev", False),
            ("firmware_dev", "fwdev@gsmvault.dev", False),
            ("rom_chef", "romchef@gsmvault.dev", False),
            ("test_pilot", "pilot@gsmvault.dev", False),
            ("brick_doctor", "brick@gsmvault.dev", False),
            ("signal_seeker", "signal@gsmvault.dev", False),
            ("gsm_guru", "guru@gsmvault.dev", False),
        ]
        for uname, email, is_staff in user_data:
            try:
                u = User.objects.get(username=uname)
            except User.DoesNotExist:
                u = User.objects.create_user(  # type: ignore[attr-defined]
                    username=uname,
                    email=email,
                    password="testpass123",  # noqa: S106
                    is_staff=is_staff,
                    is_active=True,
                )
            users.append(u)

        admin_user, flash_user, fwdev, romchef, pilot, brick_doc, signal, guru = users

        # --- Trust Levels ---
        trust_levels = [
            (0, "New User", "#9ca3af", 0, 0, 0, 0, 0, 0),
            (1, "Basic", "#60a5fa", 1, 3, 0, 0, 1, 2),
            (2, "Member", "#34d399", 5, 15, 5, 3, 7, 10),
            (3, "Regular", "#a78bfa", 15, 50, 20, 15, 30, 50),
            (4, "Leader", "#f59e0b", 50, 200, 100, 50, 90, 200),
        ]
        for (
            level,
            title,
            color,
            min_topics,
            min_replies,
            min_likes_r,
            min_likes_g,
            min_days,
            min_read,
        ) in trust_levels:
            ForumTrustLevel.objects.update_or_create(
                level=level,
                defaults={
                    "title": title,
                    "color": color,
                    "min_topics_created": min_topics,
                    "min_replies_posted": min_replies,
                    "min_likes_received": min_likes_r,
                    "min_likes_given": min_likes_g,
                    "min_days_visited": min_days,
                    "min_topics_read": min_read,
                    "can_flag": level >= 1,
                    "can_create_polls": level >= 2,
                    "can_upload_attachments": level >= 1,
                    "can_send_private_messages": level >= 1,
                    "can_edit_own_posts": True,
                    "max_daily_topics": 5 + level * 5,
                    "max_daily_replies": 20 + level * 20,
                },
            )

        # --- Reactions ---
        reactions_data = [
            ("Like", "👍", "thumbs-up", 1, True),
            ("Love", "❤️", "heart", 2, True),
            ("Insightful", "💡", "lightbulb", 2, True),
            ("Funny", "😂", "smile", 1, True),
            ("Agree", "✅", "check", 1, True),
            ("Disagree", "❌", "x", -1, False),
        ]
        for i, (name, emoji, icon, score, positive) in enumerate(reactions_data):
            ForumReaction.objects.update_or_create(
                name=name,
                defaults={
                    "emoji": emoji,
                    "icon": icon,
                    "score": score,
                    "sort_order": i,
                    "is_positive": positive,
                    "is_active": True,
                },
            )

        # --- Topic Prefixes ---
        prefixes_data = [
            ("SOLVED", "solved", "#22c55e"),
            ("HELP", "help", "#ef4444"),
            ("GUIDE", "guide", "#3b82f6"),
            ("ROM", "rom", "#a855f7"),
            ("MOD", "mod", "#f97316"),
            ("NEWS", "news", "#06b6d4"),
            ("REVIEW", "review", "#eab308"),
            ("FIRMWARE", "firmware", "#ec4899"),
        ]
        for name, slug, color in prefixes_data:
            ForumTopicPrefix.objects.update_or_create(
                slug=slug,
                defaults={"name": name, "color": color, "is_active": True},
            )

        # --- Categories ---
        cats: dict[str, ForumCategory] = {}

        cat_data = [
            # (title, slug, description, icon, color, parent_slug)
            (
                "General Discussion",
                "general",
                "Chat about anything GSM & firmware related",
                "message-circle",
                "#6366f1",
                None,
            ),
            (
                "Announcements",
                "announcements",
                "Official GSMVault news and updates",
                "megaphone",
                "#f59e0b",
                None,
            ),
            (
                "Samsung",
                "samsung",
                "Samsung firmware, ROMs, and discussion",
                "smartphone",
                "#1e40af",
                None,
            ),
            (
                "Samsung Galaxy S Series",
                "samsung-galaxy-s",
                "Galaxy S24, S23, S22 and older",
                "smartphone",
                "#3b82f6",
                "samsung",
            ),
            (
                "Samsung Galaxy A Series",
                "samsung-galaxy-a",
                "Galaxy A55, A35, A15 and budget lineup",
                "smartphone",
                "#60a5fa",
                "samsung",
            ),
            (
                "Xiaomi",
                "xiaomi",
                "Xiaomi, Redmi, POCO firmware and MIUI discussion",
                "smartphone",
                "#ff6900",
                None,
            ),
            (
                "Xiaomi Redmi Note",
                "xiaomi-redmi-note",
                "Redmi Note 13, 12, 11 series",
                "smartphone",
                "#f97316",
                "xiaomi",
            ),
            (
                "Huawei",
                "huawei",
                "Huawei & Honor firmware, EMUI, HarmonyOS",
                "smartphone",
                "#e11d48",
                None,
            ),
            (
                "Flash Tools & Guides",
                "flash-tools",
                "SP Flash Tool, Odin, QFIL, and flashing guides",
                "wrench",
                "#22c55e",
                None,
            ),
            (
                "Firmware Requests",
                "firmware-requests",
                "Request specific firmware files",
                "download",
                "#8b5cf6",
                None,
            ),
            (
                "Brick Recovery",
                "brick-recovery",
                "Unbrick guides and recovery help",
                "shield-alert",
                "#ef4444",
                None,
            ),
            (
                "Marketplace",
                "marketplace",
                "Buy, sell, trade devices and services",
                "shopping-bag",
                "#14b8a6",
                None,
            ),
        ]

        for title, slug, desc, icon, color, parent_slug in cat_data:
            parent = cats.get(parent_slug) if parent_slug else None
            cat, _ = ForumCategory.objects.update_or_create(
                slug=slug,
                defaults={
                    "title": title,
                    "description": desc,
                    "icon": icon,
                    "color": color,
                    "parent": parent,
                    "is_visible": True,
                    "is_removed": False,
                },
            )
            cats[slug] = cat

        # Wire brand_link for device categories (graceful — skip if brands missing)
        try:
            from apps.firmwares.models import Brand

            brand_map = {
                "samsung": "samsung",
                "xiaomi": "xiaomi",
                "huawei": "huawei",
            }
            for cat_slug, brand_slug in brand_map.items():
                brand = Brand.objects.filter(slug=brand_slug).first()
                if brand and cat_slug in cats:
                    ForumCategory.objects.filter(pk=cats[cat_slug].pk).update(
                        brand_link=brand
                    )
                    self.stdout.write(
                        f"  Linked category '{cat_slug}' → brand '{brand_slug}'"
                    )
        except Exception:  # noqa: BLE001
            self.stdout.write(
                self.style.WARNING("  Skipping brand_link (firmwares app unavailable)")
            )

        # --- Forum User Profiles ---
        profile_data = [
            (admin_user, 4, "Site Admin", 2500, 120, 350),
            (flash_user, 3, "Flash Expert", 1800, 95, 220),
            (fwdev, 3, "Firmware Developer", 1200, 60, 180),
            (romchef, 2, "Custom ROM Chef", 800, 45, 95),
            (pilot, 2, "Beta Tester", 600, 30, 72),
            (brick_doc, 3, "Unbrick Specialist", 1500, 80, 200),
            (signal, 1, "Newcomer", 150, 8, 15),
            (guru, 4, "GSM Legend", 3000, 150, 500),
        ]
        for user, level, title, rep, topics, replies in profile_data:
            ForumUserProfile.objects.update_or_create(
                user=user,
                defaults={
                    "trust_level": level,
                    "custom_title": title,
                    "reputation": rep,
                    "topic_count": topics,
                    "reply_count": replies,
                    "likes_received": rep // 3,
                    "likes_given": rep // 5,
                    "solutions_count": topics // 10,
                    "days_visited": 30 + level * 20,
                    "topics_read": replies * 2,
                    "last_active_at": timezone.now(),
                    "last_posted_at": timezone.now(),
                },
            )

        # --- Topics ---
        topics_data = [
            # (category_slug, user, title, content, topic_type, is_pinned)
            (
                "announcements",
                admin_user,
                "Welcome to GSMVault Forum — Read Before Posting",
                "Welcome to the GSMVault community forum!\n\n## Rules\n1. Be respectful\n2. No spam or self-promotion\n3. Search before posting\n4. Use appropriate prefixes\n5. Share knowledge generously\n\n## How to get started\n- Browse categories and read existing discussions\n- Ask questions in the right category\n- Help others and earn reputation\n- Unlock higher trust levels for more features\n\nHappy flashing! 📱⚡",
                TopicType.NEWS,
                True,
            ),
            (
                "samsung-galaxy-s",
                flash_user,
                "[GUIDE] How to Flash Samsung Galaxy S24 Ultra with Odin",
                "# Complete Flashing Guide for Galaxy S24 Ultra\n\n## Requirements\n- Odin v3.14.4 or newer\n- Samsung USB drivers\n- A full charge (80%+ recommended)\n- Original USB-C cable\n\n## Steps\n1. **Download** the correct firmware from GSMVault\n2. **Extract** the ZIP — you'll get AP, BL, CP, CSC files\n3. **Boot into Download Mode**: Power off → Vol Down + Power while connecting USB\n4. **Open Odin** and load files into correct slots\n5. **Click Start** and wait 5-10 minutes\n6. Device will reboot automatically\n\n## Common Issues\n- **FAIL at system.img**: Try a different CSC file (HOME_CSC for data preservation)\n- **Stuck on logo**: Wipe cache from recovery mode\n- **Odin not detecting**: Reinstall Samsung drivers\n\n> ⚠️ Always backup before flashing!\n\nFeel free to ask questions below.",
                TopicType.GUIDE,
                False,
            ),
            (
                "samsung-galaxy-s",
                fwdev,
                "Samsung Galaxy S24 — Official One UI 7.0 Firmware Discussion",
                "Samsung has started rolling out **One UI 7.0** based on Android 15 for the Galaxy S24 series.\n\n## What's New\n- Redesigned Quick Settings panel\n- New notification grouping\n- Improved RAM management\n- Battery life optimization\n- Enhanced security patches (March 2025)\n\n## Download Links\n- SM-S928B (Exynos, Global): Available on GSMVault\n- SM-S928U (Snapdragon, US): Coming soon\n- SM-S928N (Korea): Available\n\nPlease report any issues you encounter after updating.",
                TopicType.FIRMWARE,
                False,
            ),
            (
                "xiaomi-redmi-note",
                romchef,
                "Redmi Note 13 Pro — Custom ROM Comparison Thread",
                "Comparing popular custom ROMs for Redmi Note 13 Pro (garnet).\n\n| ROM | Android | Battery | Performance | Stability |\n|-----|---------|---------|-------------|----------|\n| LineageOS 21 | 14 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |\n| PixelExperience | 14 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |\n| crDroid | 14 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |\n| EvolutionX | 14 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |\n\nAll ROMs require unlocked bootloader + TWRP.\n\nShare your experience below!",
                TopicType.REVIEW,
                False,
            ),
            (
                "brick-recovery",
                brick_doc,
                "[HELP] Galaxy A55 Stuck in Bootloop After Failed Update",
                "My Galaxy A55 is stuck in a bootloop after a failed OTA update. It shows the Samsung logo then restarts endlessly.\n\n**What I've tried:**\n- Factory reset from recovery — didn't help\n- Wiping cache partition — no change\n- Safe mode — can't access it\n\n**Device info:**\n- Model: SM-A556B\n- Region: EUX\n- Last firmware: A556BXXU1AXK1\n\nAny suggestions? I have Odin but I'm not sure which firmware to flash.",
                TopicType.BUG_REPORT,
                False,
            ),
            (
                "flash-tools",
                guru,
                "[GUIDE] SP Flash Tool Complete Tutorial for MediaTek Devices",
                "# SP Flash Tool — The Definitive Guide\n\n## What is SP Flash Tool?\nSP Flash Tool (SmartPhone Flash Tool) is the official flashing tool for MediaTek chipset devices.\n\n## Supported Chipsets\nMT6580, MT6735, MT6739, MT6750, MT6761, MT6765 (Helio P35), MT6768 (Helio G85), MT6769, MT6771 (Helio P60), MT6779 (Helio G90T), MT6781 (Helio G96), MT6785 (Helio G90), MT6833 (Dimensity 700), MT6853 (Dimensity 720), MT6877 (Dimensity 900), MT6893 (Dimensity 1200), MT6895 (Dimensity 8100), and many more.\n\n## Download\nLatest version available at GSMVault: **SP Flash Tool v5.2236**\n\n## Basic Steps\n1. Install MTK USB drivers\n2. Load scatter file\n3. Select firmware files\n4. Click Download\n5. Connect device in BROM/preloader mode\n\n> 💡 Pro tip: If your device has Auth (DA), you need to bypass it first.",
                TopicType.GUIDE,
                True,
            ),
            (
                "firmware-requests",
                signal,
                "Need Samsung SM-A156B firmware (Galaxy A15 5G) — XEF Region",
                "Looking for the latest official firmware for:\n- **Model**: SM-A156B\n- **Region**: XEF (France)\n- **Android version**: 14\n\nCan't find it on the regular download page. Anyone have it?",
                TopicType.DISCUSSION,
                False,
            ),
            (
                "general",
                pilot,
                "What's Your Daily Driver Phone in 2025?",
                "Curious what everyone here is using as their daily driver!\n\nI'm currently on:\n- **Primary**: Samsung Galaxy S24 Ultra (custom firmware, Google Camera port)\n- **Secondary**: Xiaomi Poco F6 (LineageOS 21)\n\nI keep the secondary as a test device for new ROMs before recommending them.\n\nWhat about you?",
                TopicType.DISCUSSION,
                False,
            ),
            (
                "huawei",
                fwdev,
                "Huawei P60 Pro — HarmonyOS 4.2 Firmware Thread",
                "HarmonyOS 4.2 is rolling out for the Huawei P60 Pro.\n\nThe update brings:\n- Improved multi-device connectivity\n- New gesture navigation options\n- Enhanced privacy dashboard\n- Better app compatibility layer\n\n**Note**: Huawei firmware requires special handling due to bootloader restrictions.",
                TopicType.FIRMWARE,
                False,
            ),
            (
                "marketplace",
                romchef,
                "WTS: Unlocked Samsung Galaxy S23 FE — Great for Firmware Testing",
                "Selling my Galaxy S23 FE (SM-S711B, Exynos variant).\n\n- Bootloader unlocked\n- Knox warranty voided (expected for dev use)\n- Good condition, minor screen scratches\n- Includes original box and charger\n- TWRP installed\n\nPerfect for firmware development and testing.\n\n**Price**: $280 USD shipped worldwide\n\nDM me if interested.",
                TopicType.DISCUSSION,
                False,
            ),
        ]

        created_topics: list[ForumTopic] = []
        for cat_slug, user, title, content, topic_type, pinned in topics_data:
            category = cats[cat_slug]
            if ForumTopic.objects.filter(title=title, category=category).exists():
                topic = ForumTopic.objects.get(title=title, category=category)
            else:
                topic = services.create_topic(
                    user=user,
                    category=category,
                    title=title,
                    content=content,
                )
                topic.topic_type = topic_type
                if pinned:
                    topic.is_pinned = True
                topic.save(update_fields=["topic_type", "is_pinned", "updated_at"])
            created_topics.append(topic)

        # --- Replies ---
        reply_data = [
            # (topic_index, user, content)
            (
                1,
                romchef,
                "Great guide! One tip — always use the HOME_CSC file if you want to keep your data. Regular CSC does a factory reset.",
            ),
            (
                1,
                pilot,
                "Followed this guide and flashed successfully! S24 Ultra SM-S928B on latest firmware now. Thanks @flash_master!",
            ),
            (
                1,
                signal,
                "Does this work with the S24+ as well or are the firmware files different?",
            ),
            (
                1,
                flash_user,
                "@signal_seeker Different model, different firmware files. But the process with Odin is identical. Just make sure you download SM-S926B firmware.",
            ),
            (
                1,
                brick_doc,
                "I'd add that you should ALWAYS disable Windows driver signature enforcement if Odin doesn't detect your device. That solves 90% of connection issues.",
            ),
            (
                2,
                flash_user,
                "Can confirm the Exynos variant is smooth. Battery improvement is noticeable — getting about 30 minutes more SOT compared to One UI 6.1.",
            ),
            (
                2,
                guru,
                "The new Quick Settings layout is controversial, but I think it's more efficient once you get used to it.",
            ),
            (
                2,
                pilot,
                "Any reports of heating issues? Previous updates had thermal throttling problems.",
            ),
            (
                2,
                fwdev,
                "@test_pilot No reports so far. Samsung seems to have addressed the thermal management in this build.",
            ),
            (
                3,
                fwdev,
                "PixelExperience is my pick for stability. LineageOS for long-term support.",
            ),
            (
                3,
                guru,
                "crDroid with custom kernel gives the best benchmark scores, but battery takes a hit. It's a trade-off.",
            ),
            (
                3,
                flash_user,
                "Great comparison table! Maybe add DerpFest? It's becoming popular for MTK Dimensity devices.",
            ),
            (
                4,
                flash_user,
                "Flash the latest stock firmware via Odin. Use the full 4-file firmware (AP+BL+CP+CSC). That should fix the bootloop.",
            ),
            (
                4,
                guru,
                "Make sure you use the HOME_CSC if you want to try preserving data first. If that fails, use regular CSC for a clean flash.",
            ),
            (
                4,
                admin_user,
                "Also try holding Vol Up + Power to enter recovery mode. From there, try 'Repair Apps' option before full flash.",
            ),
            (
                4,
                brick_doc,
                "UPDATE: Managed to fix it with a full Odin flash. @flash_master and @gsm_guru were right — HOME_CSC did the trick! Data preserved. 🎉",
            ),
            (
                5,
                flash_user,
                "This is the best SP Flash Tool guide I've seen. Bookmarked.",
            ),
            (
                5,
                romchef,
                "For anyone on Linux — there's a fork called 'SP Flash Tool Linux' on GitHub that works well.",
            ),
            (
                6,
                fwdev,
                "I might have the XEF version. Let me check my collection tonight and upload it.",
            ),
            (
                6,
                signal,
                "@firmware_dev That would be amazing! I've been looking everywhere.",
            ),
            (
                7,
                guru,
                "Galaxy S24 Ultra as daily, Pixel 8 Pro as test device. I love having stock Android for comparison.",
            ),
            (
                7,
                brick_doc,
                "Xiaomi 14 Ultra with EU ROM. The camera is unbelievable, and the EU ROM removes all the bloatware.",
            ),
            (
                7,
                admin_user,
                "Nothing Phone (2a) running GrapheneOS. Privacy-focused daily, Samsung for testing.",
            ),
        ]

        for topic_idx, user, content in reply_data:
            topic = created_topics[topic_idx]
            if not ForumReply.objects.filter(
                topic=topic, user=user, content=content[:50]
            ).exists():
                services.create_reply(
                    topic=topic,
                    user=user,
                    content=content,
                )

        # --- Polls ---
        poll_topic = created_topics[7]  # "Daily Driver" topic
        if not ForumPoll.objects.filter(topic=poll_topic).exists():
            poll = ForumPoll.objects.create(
                topic=poll_topic,
                title="What brand is your daily driver?",
                mode="single",
                is_secret=False,
                vote_count=0,
            )
            for i, choice in enumerate(
                [
                    "Samsung",
                    "Xiaomi",
                    "Google Pixel",
                    "OnePlus",
                    "Apple",
                    "Huawei",
                    "Other",
                ]
            ):
                ForumPollChoice.objects.create(
                    poll=poll, description=choice, sort_order=i, vote_count=0
                )

        # --- Topic Tags ---
        tag_data = [
            (1, ["galaxy-s24", "odin", "flashing-guide", "tutorial"]),
            (2, ["one-ui-7", "android-15", "samsung", "firmware-update"]),
            (3, ["custom-rom", "lineageos", "redmi-note-13", "comparison"]),
            (4, ["bootloop", "galaxy-a55", "unbrick", "help-needed"]),
            (5, ["sp-flash-tool", "mediatek", "tutorial", "mtk"]),
        ]
        for topic_idx, tags in tag_data:
            topic = created_topics[topic_idx]
            for tag_name in tags:
                ForumTopicTag.objects.get_or_create(
                    topic=topic,
                    slug=tag_name,
                    defaults={"name": tag_name.replace("-", " ").title()},
                )

        # --- 4PDA Wiki Header (on the Galaxy S24 firmware topic) ---
        fw_topic = created_topics[2]
        if not fw_topic.wiki_header:
            services.update_wiki_header(
                fw_topic,
                user=fwdev,
                content=(
                    "## Samsung Galaxy S24 — Firmware Repository\n\n"
                    "**Latest Version**: One UI 7.0 (Android 15) — Build S928BXXU2AXL1\n\n"
                    "### Quick Links\n"
                    "- [Download Latest Firmware](#downloads)\n"
                    "- [Flashing Guide](#guide)\n"
                    "- [Known Issues](#issues)\n"
                    "- [Changelog](#changelog)\n\n"
                    "### Supported Variants\n"
                    "| Model | Chipset | Region |\n"
                    "|-------|---------|--------|\n"
                    "| SM-S928B | Exynos 2400 | Global |\n"
                    "| SM-S928U | Snapdragon 8 Gen 3 | USA |\n"
                    "| SM-S928N | Exynos 2400 | Korea |\n\n"
                    "> 📌 Always check your exact model number in Settings → About Phone"
                ),
            )

        # --- 4PDA Changelog (on firmware topic) ---
        if not ForumChangelog.objects.filter(topic=fw_topic).exists():
            changelog_data = [
                (
                    "S928BXXU2AXL1",
                    "- Security patch: March 2025\n- Fixed camera crash on Pro mode\n- Improved 5G connectivity\n- Battery drain fix for Bluetooth",
                    "2025-03-01",
                ),
                (
                    "S928BXXU2AXK1",
                    "- One UI 7.0 initial release\n- Redesigned Quick Settings\n- New notification grouping\n- Enhanced RAM management",
                    "2025-02-15",
                ),
                (
                    "S928BXXU1AXJ2",
                    "- Security patch: January 2025\n- WiFi stability fix\n- Camera processing speed improvement",
                    "2025-01-05",
                ),
            ]
            for version, changes, released in changelog_data:
                from django.utils.dateparse import parse_date

                ForumChangelog.objects.create(
                    topic=fw_topic,
                    version=version,
                    changes=changes,
                    changes_html=services.render_markdown(changes),
                    released_at=parse_date(released),
                    added_by=fwdev,
                )

        # --- 4PDA FAQ entries (on SP Flash Tool guide) ---
        guide_topic = created_topics[5]
        first_reply = ForumReply.objects.filter(topic=guide_topic).first()
        if first_reply and not ForumFAQEntry.objects.filter(topic=guide_topic).exists():
            ForumFAQEntry.objects.create(
                topic=guide_topic,
                reply=first_reply,
                question="How to install MTK USB drivers on Windows 11?",
                sort_order=0,
            )

        # --- Online Users ---
        for user in users[:5]:
            ForumOnlineUser.objects.update_or_create(
                user=user,
                defaults={"location": "Forum Index"},
            )

        # --- Recount categories ---
        for cat in ForumCategory.objects.all():
            services.recount_category(cat)

        self.stdout.write(
            self.style.SUCCESS(
                f"✅ Forum seeded: {len(users)} users, "
                f"{ForumCategory.objects.count()} categories, "
                f"{ForumTopic.objects.count()} topics, "
                f"{ForumReply.objects.count()} replies"
            )
        )
