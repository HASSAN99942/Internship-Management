# MOBILE.md — Flutter App Context for Claude Code

> The mobile counterpart to CLAUDE.md / ARCHITECTURE.md / DESIGN_SYSTEM.md.
> The Flutter app is a NEW CLIENT of the existing Django REST API — no backend
> rewrite. It targets iOS and Android with full feature parity with the web app,
> and reuses the same visual identity (violet brand, status colors, bold type,
> dark mode) expressed via Material 3.

Authoritative references (already in /docs): SRS_Internship_Platform.md (features,
data model, API), ARCHITECTURE.md (layering principles), DESIGN_SYSTEM.md (the
visual system this app mirrors). When in doubt, match the web app's behavior.

## Location & platforms
- Lives in `mobile/` at the repo root (alongside `backend/` and `frontend/`).
- Targets: iOS and Android, one Flutter codebase.

## Stack
- Flutter (stable) + Dart, Material 3.
- **dio** — HTTP client with an interceptor for JWT + refresh.
- **flutter_riverpod** — state management (mirrors the web's feature-based,
  separated-concerns approach).
- **flutter_secure_storage** — store JWT access/refresh tokens in Keychain/Keystore.
- **go_router** — declarative routing with auth/role guards.
- **google_fonts** — Space Grotesk (display/headings) + Inter (body).
- **json_serializable** (+ build_runner) — typed models per feature.
- **image_picker / file_picker** — CV and report/task file uploads via native picker.
- **intl** — date/time formatting.
- **flutter_dotenv** (or --dart-define) — API base URL & config per environment.

## API & auth (same contract as web)
- Base path `/api/v1/`, JSON, bearer JWT in the `Authorization: Bearer <access>`
  header. Same endpoints the web app uses (see SRS §8).
- Auth = bearer tokens in headers (NOT cookies). On login, store access + refresh
  in flutter_secure_storage.
- A single Dio instance in `core/api/` with an interceptor that:
  attaches the access token to every request; on 401, transparently calls the
  refresh endpoint, stores the new token, and retries the original request; on
  refresh failure, clears tokens and routes to login. This is the mobile twin of
  the web central API client — token logic lives in exactly one place.
- **Networking host gotcha (document in README):** a device/emulator cannot reach
  `localhost`. Use the Android emulator alias `10.0.2.2`, `localhost` on the iOS
  simulator, and the dev machine's LAN IP on a physical device. Keep the base URL
  in env/config, never hardcoded.
- **Media URLs:** the API may return relative media paths (CV, report files).
  Build absolute URLs against the API origin before loading/downloading.

## Backend touch-ups (minimal, only if needed)
- Ensure `ALLOWED_HOSTS` includes the dev machine IP used by devices.
- CORS is largely irrelevant for native requests, but leave existing config intact.
- No new endpoints — the mobile app consumes the existing API as-is.

## Project structure (feature-based, mirrors the web)
```
mobile/
  lib/
    main.dart
    app.dart                 # MaterialApp.router + ThemeData (light/dark)
    core/
      api/                   # dio client, auth interceptor, ApiError model
      auth/                  # token storage, auth controller/provider, session
      theme/                 # colors.dart, typography.dart, app_theme.dart
      router/                # go_router config + guards (auth + role)
      widgets/               # shared UI: AppScaffold (bottom nav), StatusBadge,
                             #   primary buttons, loading skeletons, empty states
    features/
      auth/                  # data (models, repository) / providers / screens / widgets
      offers/
      applications/
      internships/           # internship detail/dashboard, tasks, reports
      messaging/
      evaluations/
      notifications/
  .env / config
  pubspec.yaml
```
Each feature folder is self-contained: models, a repository (calls the Dio
client), Riverpod providers/controllers, screens, and feature widgets. Shared
presentational widgets live in `core/widgets/`. Keep view logic out of widgets —
repositories do I/O, providers hold state, screens compose.

## Theming — match DESIGN_SYSTEM.md via Material 3
Build a light and dark `ColorScheme` from the web tokens (convert the HSL values
in DESIGN_SYSTEM.md to Flutter `Color`s). Reference values:

Light: primary violet `#7C3AED`, onPrimary `#FFFFFF`, surface/background
`#FFFFFF`, onSurface `#0F1729`, surfaceVariant `#F1F5F9`, muted text `#64748B`,
outline/border `#E2E8F0`.

Dark: primary (lightened) `#9767E4`, background `#0F0E15`, surface/card `#1A1722`,
onSurface `#F8FAFC`, muted text `#A29DB0`, outline `#2B2738`.

Typography: `GoogleFonts.spaceGrotesk` for display/headlines/titles (bold,
expressive), `GoogleFonts.inter` for body/labels. Build a Material 3 `TextTheme`
so headings are large and bold like the web.

Shape: rounded corners ~12px (`--radius: 0.75rem` equivalent) on cards, buttons,
inputs. Soft elevation, generous spacing.

Dark mode: follow the system setting by default, with an in-app toggle (persist
the choice). `themeMode` driven by a Riverpod provider.

### StatusBadge (same mapping as web)
A reusable widget mapping a domain status string to a colored chip:
- success (emerald): published, active, validated, accepted
- warning (amber): pending, pending_academic_validation, submitted, changes_requested
- info (sky): informational/in-progress
- neutral (slate): draft, open, withdrawn
- destructive (rose): closed, rejected, cancelled
Tinted background + same-family foreground; works in light and dark.

## Navigation — bottom nav per role (the sidebar's mobile form)
An `AppScaffold` with a Material 3 `NavigationBar`. Tabs mirror the web role nav:
- student: Dashboard, Offers, Applications, Internship, Messages (+ Evaluations reachable from internship)
- company: Dashboard, Offers, Applications, Internships, Messages
- teacher: Dashboard, Agreements, Students, Messages (+ Evaluations from internship)
- admin: admin is managed via the Django admin site; the mobile app does not need
  a full admin UI (a minimal read-only view is optional).
Keep tab count to ~5; reach secondary screens via stack navigation. Notifications
live in a top app-bar bell with an unread badge (mirrors the web topbar).

## Parity & conventions
- Feature set matches the web app phase-for-phase (offers, applications &
  validation, monitoring with tasks/reports, messaging, evaluations,
  notifications).
- Messaging bubbles use the same `isOwn = message.sender.id == currentUser.id`
  rule: own messages right + primary color, others left + neutral, sender name
  shown above others' bubbles in the group thread.
- Loading states use skeleton/shimmer placeholders, not bare spinners, for lists.
- Every color comes from the theme/ColorScheme — nothing hardcoded that breaks in
  dark mode.
- Build in phases (see the mobile build plan). Each phase ends with a runnable,
  testable slice. Show a plan before large changes.
