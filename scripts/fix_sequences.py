"""Fix PostgreSQL auto-increment sequences after manual data inserts."""

import os

import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "app.settings_dev")
django.setup()

from django.db import connection  # noqa: E402

with connection.cursor() as cursor:
    cursor.execute(
        "SELECT setval('users_customuser_id_seq', "
        "(SELECT COALESCE(MAX(id), 0) FROM users_customuser))"
    )
    val = cursor.fetchone()
    print(f"users_customuser_id_seq reset to {val[0] if val else 'N/A'}")
