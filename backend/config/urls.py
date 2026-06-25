"""Root URL configuration.

All API endpoints are versioned under ``/api/v1/``. App routers are included
here; each app owns its own ``urls.py``.
"""

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularRedocView, SpectacularSwaggerView

urlpatterns = [
    path("admin/", admin.site.urls),
    # OpenAPI schema + interactive docs (unauthenticated; no sensitive data exposed)
    path("api/v1/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/v1/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
    path("api/v1/redoc/", SpectacularRedocView.as_view(url_name="schema"), name="redoc"),
    path("api/v1/", include("core.urls")),
    path("api/v1/", include("accounts.urls")),
    path("api/v1/", include("offers.urls")),
    path("api/v1/", include("applications.urls")),
    path("api/v1/", include("internships.urls")),
    path("api/v1/", include("messaging.urls")),
    path("api/v1/", include("evaluations.urls")),
    path("api/v1/", include("notifications.urls")),
    path("api/v1/", include("administration.urls")),
]

# Serve uploaded media (e.g. CVs) from the dev server.
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
