"""Reusable upload validation for serializers (file type + size)."""

from rest_framework import serializers

# Documents and images accepted for task submissions and reports.
DEFAULT_ALLOWED_EXTENSIONS = ("pdf", "doc", "docx", "png", "jpg", "jpeg", "gif")
DEFAULT_MAX_SIZE_MB = 5


def validate_upload(
    value,
    *,
    allowed_extensions=DEFAULT_ALLOWED_EXTENSIONS,
    max_mb: int = DEFAULT_MAX_SIZE_MB,
):
    """Validate an uploaded file's extension and size.

    Returns the value unchanged (so it can be used inline in a serializer's
    ``validate_<field>``); raises ``serializers.ValidationError`` otherwise.
    ``None`` passes through (optional fields).
    """
    if value is None:
        return value

    name = (getattr(value, "name", "") or "").lower()
    extension = name.rsplit(".", 1)[-1] if "." in name else ""
    if extension not in allowed_extensions:
        allowed = ", ".join(allowed_extensions)
        raise serializers.ValidationError(f"File must be one of: {allowed}.")

    if value.size > max_mb * 1024 * 1024:
        raise serializers.ValidationError(f"File must be {max_mb} MB or smaller.")

    return value
