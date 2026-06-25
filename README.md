# Internship Management & Student Monitoring Platform

A web application that digitises the full internship lifecycle: account creation,
offer posting, application & validation, mission monitoring (tasks/reports),
messaging, and evaluation.

---

## Tech stack

| Layer | Technology |
|---|---|
| Backend | Python 3.11, Django 5, Django REST Framework |
| Auth | JWT via `djangorestframework-simplejwt` |
| Frontend | Next.js 14 (App Router), TypeScript, Tailwind CSS |
| Database | SQLite (dev) — swap to PostgreSQL via `DATABASE_URL` (no code change) |
| API schema | `drf-spectacular` (OpenAPI 3 + Swagger UI) |

---

## Repository layout

```
/
  backend/
    config/            # settings, urls, asgi/wsgi
    accounts/          # custom User, role profiles, auth endpoints
    offers/            # job offer CRUD
    applications/      # apply, accept, reject
    internships/       # Internship, Task, Report
    messaging/         # MessageThread, Message
    evaluations/       # company + teacher evaluations
    notifications/     # in-app notification feed
    administration/    # admin oversight endpoints
    core/              # shared utilities; seed management command
    manage.py
    requirements.txt
    .env.example
  frontend/
    app/
      (auth)/          # /login, /register
      (student)/       # student dashboard
      (company)/       # company dashboard
      (teacher)/       # teacher dashboard
      (admin)/         # admin panel (Django admin used for user management)
    lib/api/           # typed API client, auth helpers, all API call definitions
    components/        # shared UI components
    .env.local.example
  docs/
    SRS_Internship_Platform.md   # full specification
    BUILD_PLAN.md                # phase-by-phase build order
    TEST_PLAN.md                 # manual QA checklist
    DEPLOYMENT.md                # local setup + production deploy guide
    diagrams/                    # ER, class, use case, sequence, state, activity
  CLAUDE.md                      # project conventions for Claude Code
```

---

## Quick start

### Prerequisites

- Python 3.11+
- Node.js 18+

### 1. Backend

```bash
cd backend

python -m venv venv
# Windows (PowerShell):
venv\Scripts\Activate.ps1
# macOS / Linux:
# source venv/bin/activate

pip install -r requirements.txt

copy .env.example .env          # Windows
# cp .env.example .env          # macOS / Linux

python manage.py migrate
python manage.py seed           # load demo data (optional — see below)
python manage.py runserver
```

### 2. Frontend

```bash
cd frontend
npm install

copy .env.local.example .env.local    # Windows
# cp .env.local.example .env.local    # macOS / Linux

npm run dev
```

App: `http://localhost:3000`  
API: `http://127.0.0.1:8000`  
API docs (Swagger): `http://127.0.0.1:8000/api/v1/docs/`  
API docs (Redoc): `http://127.0.0.1:8000/api/v1/redoc/`

---

## Demo credentials

Run `python manage.py seed` to create 9 demo accounts. All share the same
password (default `Demo1234!`, override with `SEED_PASSWORD=...`).

To reset and reseed a clean database: `python manage.py seed --flush`

| Role | Email | Notes |
|---|---|---|
| Admin | admin@demo.test | Django superuser |
| Teacher | marie.dupont@demo.test | Has 3 assigned students |
| Teacher | jean.martin@demo.test | Backup teacher |
| Company | hr@techcorp.demo | Active & completed internships |
| Company | hr@startuplab.demo | Published offer |
| Company | hr@innovate.demo | Draft offer only |
| Student | alice.durand@demo.test | Active internship in progress |
| Student | bob.lefebvre@demo.test | Completed internship (both evaluations done) |
| Student | carol.moreau@demo.test | Application rejected |

---

## Running tests

```bash
# Backend (from backend/ with venv active)
python manage.py test
# → 162 tests, ~11 min

# Frontend
cd frontend
npm run lint
npm run build
```

---

## Per-role guide

### Student
1. Register at `/register` (role: student).
2. Browse published offers at `/student/offers`.
3. Apply to an offer. Track status at `/student/applications`.
4. Once accepted and validated, your internship appears at `/student/internship`.
5. Complete assigned tasks and submit reports from your internship dashboard.
6. Exchange messages with your company supervisor and teacher.
7. View your evaluation once submitted by both supervisors.

### Company
1. Register at `/register` (role: company).
2. Create and publish offers at `/company/offers`.
3. Review applications at `/company/applications`. Accept or reject.
4. Once the internship is activated, assign tasks to the student.
5. Review submitted tasks and reports; validate or request changes.
6. Submit your end-of-internship evaluation.

### Teacher
1. Log in — a teacher account is created by the admin.
2. Review pending agreements at `/teacher/internships` and validate them.
3. Monitor student reports.
4. Message students and company supervisors.
5. Submit your end-of-internship evaluation.

### Admin
1. Access the Django admin at `http://127.0.0.1:8000/admin/` with the admin account.
2. Manage users, assign teachers to students, inspect any data.
3. The `/admin/` section of the frontend provides summary oversight views.

---

## Documentation

| Doc | Description |
|---|---|
| [docs/SRS_Internship_Platform.md](docs/SRS_Internship_Platform.md) | Full requirements, data model, API endpoint table |
| [docs/BUILD_PLAN.md](docs/BUILD_PLAN.md) | Phase-by-phase build order and status |
| [docs/TEST_PLAN.md](docs/TEST_PLAN.md) | Manual QA checklist for every feature |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Local setup, env vars, production deploy (Render + Vercel) |
| [docs/diagrams/](docs/diagrams/) | ER, class, use case, sequence, state, activity diagrams |
| [CLAUDE.md](CLAUDE.md) | Stack, conventions, definition of done |

---

## Deployment

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for the full guide, including:

- SQLite (dev) → PostgreSQL (prod) via `DATABASE_URL` — no code change required.
- Static files served by WhiteNoise — no separate web server needed.
- Backend on Render / VPS, frontend on Vercel.
- All required environment variables documented in `backend/.env.example` and
  `frontend/.env.local.example`.
