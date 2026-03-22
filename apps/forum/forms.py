from __future__ import annotations

from django import forms

from .models import ForumFlag, PollMode


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
