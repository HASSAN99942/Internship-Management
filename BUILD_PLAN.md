# Build Plan — Internship Management Platform

A phased backlog for building the app with Claude Code. Each phase ends with a
**runnable, demoable slice**. Build the backend slice and its matching frontend
slice together within a phase. Tackle phases in order.

For each ticket, "Done" = the [Definition of Done in `CLAUDE.md`](./CLAUDE.md) is met.

---

## Phase 0 — Project scaffolding
Goal: backend and frontend both run and can talk to each other.

- [ ] Initialise monorepo, `.gitignore`, `README.md`, commit.
- [ ] Create Django project `config` + apps: `accounts`, `offers`, `applications`, `internships`, `messaging`, `evaluations`, `notifications`.
- [ ] Install & configure DRF, `simplejwt`, `django-cors-headers`; set CORS to allow the frontend origin.
- [ ] Add `.env` handling; move `SECRET_KEY` and config out of settings.
- [ ] Add one health-check endpoint `GET /api/health/`.
- [ ] Initialise Next.js (App Router, TypeScript, Tailwind).
- [ ] Build `lib/api/` client (base URL, JSON, error handling) and a page that calls `/api/health/` to prove the connection.

**Demo:** open the frontend, see "API OK" from the health endpoint.

## Phase 1 — Accounts & authentication
Goal: all roles can register, log in, and reach a role-based dashboard.

- [ ] Custom `User` model with `role`; configure `AUTH_USER_MODEL`.
- [ ] `StudentProfile`, `CompanyProfile`, `TeacherProfile` models (see SRS §7).
- [ ] Register endpoint (creates user + role profile), login, refresh, logout.
- [ ] `GET/PATCH /api/me/` for own profile.
- [ ] JWT config; access/refresh lifetimes.
- [ ] Frontend: register & login pages, token storage + auto-refresh in API client, protected-route handling, empty role dashboards (student/company/teacher) and Django admin for admin.
- [ ] Tests: register per role, login, token refresh, unauthorised access returns 401/403.

**Demo:** register as each role → log in → land on the correct dashboard.

## Phase 2 — Internship offers
Goal: companies post offers; everyone can browse/search.

- [ ] `Offer` model + serializer + viewset (CRUD).
- [ ] Publish/close actions; status rules (`draft/published/closed`).
- [ ] List endpoint with pagination + filters (keyword, location, duration, company).
- [ ] Permissions: only owning company (or admin) edits; published offers visible to all authenticated users.
- [ ] Frontend: offer create/edit form (company), offer list with filters, offer detail page.
- [ ] Tests: create/publish/close, filtering, permission checks.

**Demo:** company publishes an offer; student finds it via search and opens it.

## Phase 3 — Applications & validation
Goal: the core spine — apply → accept → agreement → academic validation.

- [ ] `Application` model (unique per offer+student) + endpoints: apply, withdraw, accept, reject.
- [ ] On accept: create `Internship` (`pending_academic_validation`) + `MessageThread`, in one atomic transaction.
- [ ] `Internship` validation endpoint (teacher/admin) → status `active`.
- [ ] CV file upload on application (validate type/size).
- [ ] Frontend: application form (student), application tracker, company review screen (accept/reject), teacher agreement-validation screen.
- [ ] Tests: apply, duplicate-apply blocked, accept creates internship, validation activates it, permissions.

**Demo:** student applies → company accepts → teacher validates → internship active.

## Phase 4 — Internship / mission monitoring
Goal: tasks and reports with their validation flows.

- [ ] `Task` model + endpoints (create/assign, submit, validate, request changes).
- [ ] `Report` model + endpoints (submit, validate, request changes, feedback).
- [ ] File uploads on submissions; status state machines (see SRS §10).
- [ ] Internship dashboard endpoint aggregating parties, tasks, reports, progress.
- [ ] Frontend: internship dashboard, task list + submit/validate UI, report submit/review UI.
- [ ] Tests: task & report lifecycles, role permissions on validation.

**Demo:** create a task and a report, submit them, supervisor validates; dashboard updates.

## Phase 5 — Messaging
Goal: participants of an internship exchange messages.

- [ ] `MessageThread` (1 per internship) + `Message` model + endpoints (list threads, list/send messages, mark read).
- [ ] Permissions: only the internship's participants.
- [ ] Frontend: conversation list with unread counts, thread view, send box.
- [ ] (Optional) short polling for near-real-time.
- [ ] Tests: send/receive, read state, access control.

**Demo:** student and company message each other within an internship.

## Phase 6 — Evaluation & rating
Goal: end-of-internship evaluations.

- [ ] `Evaluation` model (unique per internship+evaluator_type) + endpoints.
- [ ] Company and teacher evaluations; computed total/summary.
- [ ] (Optional) student rates the internship.
- [ ] Frontend: evaluation forms (company/teacher), summary view (student/admin).
- [ ] Tests: submit per evaluator type, read-only after submit, permissions.

**Demo:** company and teacher each evaluate; student sees the summary.

## Phase 7 — Notifications & admin polish
Goal: feedback loop and oversight.

- [ ] `Notification` model + endpoints (list, mark read); generate on key events (application status, validation, new message, new report/task).
- [ ] In-app notification UI (list + unread indicator).
- [ ] (Optional) email mirror via console backend in dev.
- [ ] Admin: stats endpoint (counts), teacher↔student assignment, content moderation via Django admin.

**Demo:** an action triggers a notification visible to the right user.

## Phase 8 — Testing, seed data, deployment, docs
Goal: defendable, runnable project.

- [ ] `python manage.py seed` command: sample students, companies, teachers, offers, and one active internship with tasks/reports/messages — for testing and the defense demo.
- [ ] Fill out the backend test suite; run a documented manual test plan covering the SRS §10 scenarios end-to-end.
- [ ] Auto-generated API schema/docs (e.g. `drf-spectacular`).
- [ ] Deployment notes: env vars, migrations, build steps (e.g. backend on a VPS/Render, frontend on Vercel); set production CORS origins.
- [ ] README: setup, run, test, seed instructions + a short per-role user guide.

**Demo:** fresh clone → follow README → seeded app running with all flows working.

---

## Suggested first prompt to Claude Code

> "Read `CLAUDE.md` and `docs/SRS_Internship_Platform.md`. Then execute Phase 0
> of `docs/BUILD_PLAN.md`: scaffold the Django backend (apps as listed) with DRF,
> simplejwt, and CORS configured, plus a `/api/health/` endpoint; and initialise
> the Next.js (App Router + TypeScript + Tailwind) frontend with an API client
> that calls the health endpoint. Show me the plan before creating files."

Then proceed one phase at a time, reviewing and committing after each.
