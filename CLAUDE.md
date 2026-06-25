# CLAUDE.md — Project Context for Claude Code

> Read this file fully before doing any work. It defines the stack, structure,
> conventions, and the build order. The full specification lives in `/docs`.

## Project

Internship Management & Student Monitoring Platform — a web app digitising the
internship lifecycle: account creation, offer posting, application & validation,
mission monitoring (tasks/reports), messaging, and evaluation.

Authoritative specification and diagrams:
- `docs/SRS_Internship_Platform.md` — full requirements, data model, API design.
- `docs/diagrams/` — ER, class, use case, sequence, state, activity, architecture.

When the SRS and this file disagree, ask before deviating. Do not invent features
that are not in the SRS.

## Stack

- **Backend:** Python 3.11+, Django, Django REST Framework, `djangorestframework-simplejwt`, `django-cors-headers`.
- **Frontend:** Next.js (App Router) + TypeScript + Tailwind CSS.
- **Database:** SQLite (dev). All DB access goes through the Django ORM only — never raw SQL — so it can be swapped for PostgreSQL later with no code change.
- **Auth:** JWT (access + refresh). Tokens handled by a central frontend API client.

## Repository layout (monorepo)

```
/
  backend/
    config/            # settings, urls, asgi/wsgi
    accounts/          # custom User + StudentProfile/CompanyProfile/TeacherProfile + auth
    offers/
    applications/
    internships/       # Internship, Task, Report
    messaging/         # MessageThread, Message
    evaluations/
    notifications/
    manage.py
    requirements.txt
  frontend/
    app/
      (auth)/          # login, register
      (student)/ (company)/ (teacher)/ (admin)/   # role dashboards
    lib/api/           # fetch client, auth, typed API calls
    components/
    package.json
  docs/                # SRS + diagrams
  .gitignore
  README.md
  CLAUDE.md
```

## Roles

`student`, `company`, `teacher`, `admin`. The custom `User` model has a `role`
field. Role-specific data lives in one-to-one profile models. The Django admin
site is used for the `admin` role's user/content management (do not build a
custom admin UI unless asked).

## Conventions

- **Python:** format with `black`, lint with `ruff`. Type hints where practical.
- **TypeScript:** ESLint + Prettier. No `any` unless unavoidable. Define types for all API responses in `lib/api/types.ts`.
- **API:** all endpoints under `/api/`, JSON only, paginated lists. Match the endpoint table in the SRS (Section 8) exactly.
- **Permissions:** enforce every role rule server-side with DRF permission classes. The frontend hides unavailable actions but never relies on hiding for security.
- **Transactions:** wrap multi-step state changes (e.g. accept application → create internship → create thread) in `transaction.atomic`.
- **Datetimes:** store UTC; format for display on the frontend.
- **Secrets:** read from environment variables via a `.env` file (use `django-environ` or `os.environ`). Never commit `.env`, `db.sqlite3`, or media files.
- **Auth tokens:** stored and attached by the central API client in `frontend/lib/api/`. Access token is short-lived; the client transparently refreshes using the refresh token. (Note: tokens are kept in browser storage for simplicity; httpOnly cookies are the more secure hardening option if time allows.)

## Definition of Done (per feature)

A feature/ticket is done when it has:
1. Django model(s) + migration.
2. DRF serializer(s) and viewset/endpoints matching the SRS.
3. Permission class enforcing the role rules.
4. Backend tests (`APITestCase`) covering the happy path and at least one permission/error case.
5. The matching Next.js page(s)/component(s) wired to the API.
6. Manual check that the end-to-end flow works against the running app.

## Commands

Backend (from `backend/`):
```
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
python manage.py test
python manage.py seed   # custom seed command (Phase 8) for demo data
```

Frontend (from `frontend/`):
```
npm install
npm run dev
npm run lint
```

## Working style

- Build one phase at a time (see `docs/BUILD_PLAN.md`). Each phase ends with a
  runnable, testable slice — build the backend slice and its matching frontend
  slice together.
- Propose a short plan before large changes; keep commits small and focused.
- Write or update tests with each feature, not at the end.
- Do not skip migrations, permissions, or input validation to save time.
