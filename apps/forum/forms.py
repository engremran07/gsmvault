from __future__ import annotations

from django import forms

from .models import ForumFlag, PollMode, TopicType


class TopicCreateForm(forms.Form):
    title = forms.CharField(
        max_length=255, widget=forms.TextInput(attrs={"placeholder": "Topic title"})
    )
    content = forms.CharField(
        widget=forms.Textarea(
            attrs={"rows": 8, "placeholder": "Write your post (Markdown supported)…"}
        )
    )

    # Optional poll fields
    poll_title = forms.CharField(
        max_length=255,
        required=False,
        widget=forms.TextInput(attrs={"placeholder": "Poll question (optional)"}),
    )
    poll_choices = forms.CharField(
        required=False,
        widget=forms.Textarea(attrs={"rows": 4, "placeholder": "One choice per line"}),
    )
    poll_mode = forms.ChoiceField(
        choices=PollMode.choices, initial=PollMode.SINGLE, required=False
    )
    poll_secret = forms.BooleanField(required=False, label="Secret ballot")
    poll_close_at = forms.DateTimeField(
        required=False, widget=forms.DateTimeInput(attrs={"type": "datetime-local"})
    )

    def clean_poll_choices(self) -> list[str]:
        raw = self.cleaned_data.get("poll_choices", "")
        if not raw:
            return []
        choices = [line.strip() for line in raw.splitlines() if line.strip()]
        return choices

    def clean(self) -> dict[str, object]:
        cleaned = super().clean() or {}
        poll_title = cleaned.get("poll_title")
        poll_choices = cleaned.get("poll_choices")
        if poll_title and (not poll_choices or len(poll_choices) < 2):  # type: ignore[arg-type]
            self.add_error("poll_choices", "A poll requires at least 2 choices.")
        return cleaned


class ReplyCreateForm(forms.Form):
    content = forms.CharField(
        widget=forms.Textarea(
            attrs={"rows": 4, "placeholder": "Write your reply (Markdown supported)…"}
        )
    )


class ReplyEditForm(forms.Form):
    content = forms.CharField(widget=forms.Textarea(attrs={"rows": 4}))


class FlagForm(forms.Form):
    reason = forms.ChoiceField(choices=ForumFlag.Reason.choices)
    detail = forms.CharField(
        required=False,
        widget=forms.Textarea(
            attrs={"rows": 3, "placeholder": "Additional details (optional)"}
        ),
    )


class PrivateTopicForm(forms.Form):
    title = forms.CharField(
        max_length=255,
        widget=forms.TextInput(attrs={"placeholder": "Conversation title"}),
    )
    content = forms.CharField(
        widget=forms.Textarea(
            attrs={"rows": 6, "placeholder": "Start the conversation…"}
        )
    )
    invite_usernames = forms.CharField(
        widget=forms.TextInput(attrs={"placeholder": "Usernames, comma separated"}),
        help_text="Invite users by username, comma separated",
    )

    def clean_invite_usernames(self) -> list[str]:
        raw = self.cleaned_data.get("invite_usernames", "")
        names = [n.strip() for n in raw.split(",") if n.strip()]
        if not names:
            raise forms.ValidationError("Invite at least one user.")
        return names


class PollVoteForm(forms.Form):
    choice_id = forms.IntegerField(widget=forms.HiddenInput)

    # For multiple-choice polls
    choice_ids = forms.CharField(required=False, widget=forms.HiddenInput)

    def clean_choice_ids(self) -> list[int]:
        raw = self.cleaned_data.get("choice_ids", "")
        if not raw:
            return []
        try:
            return [int(x) for x in raw.split(",") if x.strip()]
        except ValueError as exc:
            raise forms.ValidationError("Invalid choice IDs.") from exc


class SearchForm(forms.Form):
    q = forms.CharField(
        max_length=200,
        widget=forms.TextInput(attrs={"placeholder": "Search forum…"}),
    )


class TopicRatingForm(forms.Form):
    score = forms.IntegerField(min_value=1, max_value=5)


class TopicMoveForm(forms.Form):
    to_category = forms.IntegerField()
    reason = forms.CharField(required=False, widget=forms.Textarea(attrs={"rows": 2}))


class TopicMergeForm(forms.Form):
    target_topic_id = forms.IntegerField()


class WarningForm(forms.Form):
    user_id = forms.IntegerField(widget=forms.HiddenInput)
    severity = forms.ChoiceField(
        choices=[
            ("minor", "Minor"),
            ("moderate", "Moderate"),
            ("serious", "Serious"),
            ("final", "Final Warning"),
        ]
    )
    reason = forms.CharField(widget=forms.Textarea(attrs={"rows": 3}))
    points = forms.IntegerField(initial=1, min_value=1, max_value=100)


class IPBanForm(forms.Form):
    ip_address = forms.GenericIPAddressField()
    reason = forms.CharField(required=False, widget=forms.Textarea(attrs={"rows": 2}))


class SignatureForm(forms.Form):
    signature = forms.CharField(
        required=False,
        widget=forms.Textarea(
            attrs={"rows": 3, "placeholder": "Your signature (Markdown)…"}
        ),
    )
    custom_title = forms.CharField(
        max_length=100,
        required=False,
        widget=forms.TextInput(attrs={"placeholder": "Custom title"}),
    )
    website = forms.URLField(required=False)
    location = forms.CharField(max_length=100, required=False)


class TopicTagForm(forms.Form):
    tags = forms.CharField(
        required=False,
        widget=forms.TextInput(attrs={"placeholder": "Tags, comma separated (max 10)"}),
    )

    def clean_tags(self) -> list[str]:
        raw = self.cleaned_data.get("tags", "")
        if not raw:
            return []
        return [t.strip() for t in raw.split(",") if t.strip()][:10]


# ---------------------------------------------------------------------------
# 4PDA-style forms
# ---------------------------------------------------------------------------


class WikiHeaderForm(forms.Form):
    """Edit the wiki-style header (шапка) on a topic."""

    content = forms.CharField(
        widget=forms.Textarea(
            attrs={
                "rows": 10,
                "placeholder": "Wiki header content (Markdown supported)…",
            }
        )
    )


class ChangelogEntryForm(forms.Form):
    """Add a changelog entry to a firmware/discussion topic."""

    version = forms.CharField(
        max_length=50,
        widget=forms.TextInput(attrs={"placeholder": "e.g. 1.2.3"}),
    )
    changes = forms.CharField(
        widget=forms.Textarea(
            attrs={"rows": 4, "placeholder": "What changed in this version…"}
        )
    )
    released_at = forms.DateField(
        required=False,
        widget=forms.DateInput(attrs={"type": "date"}),
    )


class FAQEntryForm(forms.Form):
    """Mark a reply as an FAQ entry."""

    reply_id = forms.IntegerField(widget=forms.HiddenInput)
    question = forms.CharField(
        max_length=255,
        widget=forms.TextInput(attrs={"placeholder": "FAQ question label"}),
    )
    sort_order = forms.IntegerField(initial=0, required=False)


class TopicTypeForm(forms.Form):
    """Change the 4PDA-style topic type."""

    topic_type = forms.ChoiceField(choices=TopicType.choices)


class DeviceLinkForm(forms.Form):
    """Link a topic to a device model (4PDA-style)."""

    device_id = forms.IntegerField(
        widget=forms.HiddenInput,
        required=False,
    )


class AttachmentUploadForm(forms.Form):
    """Upload a file attachment to a reply."""

    file = forms.FileField(
        help_text="Max 10 MB. Allowed: images, archives, documents.",
    )

    ALLOWED_EXTENSIONS = (
        ".jpg",
        ".jpeg",
        ".png",
        ".gif",
        ".webp",
        ".svg",
        ".zip",
        ".rar",
        ".7z",
        ".tar",
        ".gz",
        ".pdf",
        ".txt",
        ".log",
        ".md",
    )
    MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB

    def clean_file(self) -> object:
        f = self.cleaned_data["file"]
        name = getattr(f, "name", "")
        ext = "." + name.rsplit(".", 1)[-1].lower() if "." in name else ""
        if ext not in self.ALLOWED_EXTENSIONS:
            raise forms.ValidationError(
                f"File type '{ext}' is not allowed. "
                f"Allowed: {', '.join(self.ALLOWED_EXTENSIONS)}"
            )
        if f.size > self.MAX_FILE_SIZE:
            raise forms.ValidationError(
                f"File too large ({f.size // 1024 // 1024} MB). Max is 10 MB."
            )
        return f
