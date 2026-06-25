from django.db import models


class TimeStampedModel(models.Model):
    """Abstract base adding self-managing created/updated timestamps.

    Concrete domain models inherit from this so every record carries an audit
    trail without repeating the fields. Stored in UTC (see settings.USE_TZ).
    """

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True
