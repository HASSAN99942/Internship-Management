# Internship Platform — Flutter Mobile Client

Cross-platform Flutter app (iOS, Android, web) for the Internship Management Platform.
Consumes the same Django REST API (/api/v1/) as the Next.js web frontend.

## Prerequisites

- Flutter SDK (stable) >= 3.10
- Dart >= 3.10
- Backend running (see backend/README.md)

## Quick start

```bash
cd mobile
cp .env.example .env        # edit API_BASE_URL for your target
flutter pub get
flutter run -d chrome --web-port 5000
```

## API base URL per target

| Target | API_BASE_URL |
|---|---|
| Flutter web (Chrome) | http://localhost:8000 |
| Android emulator | http://10.0.2.2:8000 |
| iOS simulator | http://localhost:8000 |
| Physical device | http://<LAN-IP>:8000 |

**LAN IP:** `ipconfig` (Windows) / `ifconfig` (macOS/Linux) — use the Wi-Fi adapter IPv4.
Both the device and dev machine must be on the same network.

## Backend action required

Flutter web is subject to CORS. Add the Flutter web dev origin to
`CORS_ALLOWED_ORIGINS` in `backend/config/settings.py`:

```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",   # Next.js dev
    "http://localhost:5000",   # Flutter web dev (adjust --web-port if needed)
]
```

Also add your LAN IP to `ALLOWED_HOSTS` for physical device testing.

## Project structure

```
lib/
  main.dart        entry point: loads .env, boots ProviderScope
  app.dart         MaterialApp.router + light/dark theme
  core/
    api/           Dio client, auth interceptor, ApiError
    auth/          TokenStore (Keychain / Keystore / browser storage)
    theme/         ColorScheme, TextTheme, ThemeData, ThemeMode provider
    router/        go_router config (auth/role guards in Phase 1)
    widgets/       AppScaffold (NavigationBar), StatusBadge
  features/
    health/        Health-check screen (Phase 0 smoke test)
    auth/          Login, register, session (Phase 1)
    offers/        Offer list & detail (Phase 2)
    applications/  Apply & validate (Phase 3)
    internships/   Dashboard, tasks, reports (Phase 4)
    messaging/     Thread list & chat (Phase 5)
    evaluations/   Evaluations (Phase 6)
    notifications/ Notification feed (Phase 6)
```

## Code generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
# watch mode during development:
flutter pub run build_runner watch --delete-conflicting-outputs
```
