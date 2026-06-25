"""Consistent error envelope for all API responses.

Every handled DRF exception is reshaped into:

    {"error": {"status_code": <int>, "message": <str>, "details": <optional>}}

so the frontend can rely on one error shape. Wired in via
``REST_FRAMEWORK["EXCEPTION_HANDLER"]``.
"""

from rest_framework.views import exception_handler


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is None:
        # Unhandled (non-DRF) exception: let Django produce the 500.
        return response

    data = response.data
    message = "Request failed."
    details = None

    if isinstance(data, dict):
        # A lone {"detail": "..."} is a simple message; anything else is field-level.
        if set(data.keys()) == {"detail"}:
            message = str(data["detail"])
        else:
            message = "Validation failed."
            details = data
    elif isinstance(data, list):
        message = "Validation failed."
        details = data

    error: dict = {"status_code": response.status_code, "message": message}
    if details is not None:
        error["details"] = details

    response.data = {"error": error}
    return response
