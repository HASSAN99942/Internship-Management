# Manual Test Plan — Internship Management Platform

> Use this checklist during QA and the defence demo to verify all SRS §10
> scenarios and each role's core journey.  
> Backend: `http://127.0.0.1:8000` | Frontend: `http://localhost:3000`  
> Seed credentials: run `python manage.py seed` — see printed table.

---

## Prerequisites

- Backend running (`python manage.py runserver`)
- Frontend running (`npm run dev`)
- Demo data loaded (`python manage.py seed --flush`)
- Browser devtools open (console + network) to catch silent errors

---

## 1. Authentication & Accounts (SRS AUTH-01..07)

| # | Steps | Expected result |
|---|-------|----------------|
| A1 | Navigate to `/register`; fill student form (email, password, school, program, level); submit | Redirect to student dashboard; JWT stored |
| A2 | Log out; attempt to access `/internships` directly | Redirect to `/login` |
| A3 | Log in with seeded student `alice.durand@demo.test` / `Demo1234!` | Student dashboard loads; name shown in topbar |
| A4 | Log in with seeded company `hr@techcorp.demo` | Company dashboard loads; role shown |
| A5 | Log in with seeded teacher `marie.dupont@demo.test` | Teacher dashboard loads |
| A6 | Log in with seeded admin `admin@demo.test` at `/admin/` | Django admin site accessible |
| A7 | Log in, refresh the page after >15 min (or shorten `ACCESS_TOKEN_LIFETIME_MIN`) | Still logged in (transparent refresh) |
| A8 | Log out | Redirect to login; subsequent API calls return 401 |

---

## 2. Internship Offers (SRS OFFER-01..05)

| # | Steps | Expected result |
|---|-------|----------------|
| O1 | Log in as `hr@techcorp.demo`; open "My offers"; click "New offer"; fill form; save | Offer created as draft |
| O2 | Click "Publish" on the draft offer | Status badge changes to **published** |
| O3 | Log in as `alice.durand@demo.test`; open "Offers" | TechCorp offers visible in list |
| O4 | Use search/filter by keyword "Backend" | Only matching offers returned |
| O5 | Filter by location "Paris" | Only Paris offers shown |
| O6 | Click the offer; view detail page | Title, description, skills, company name shown |
| O7 | Log in as company; open offer; click "Close" | Status badge changes to **closed** |
| O8 | As student, attempt to apply to the closed offer | Error message; apply button absent |

---

## 3. Applications & Validation (SRS APP-01..05, Workflow §10.1)

| # | Steps | Expected result |
|---|-------|----------------|
| V1 | Log in as `alice.durand@demo.test`; open offer "Backend Python Developer"; click "Apply"; fill cover message; submit | Application created (pending); listed under "My applications" |
| V2 | Try to apply again to the same offer | Error: "You have already applied to this offer" |
| V3 | Log in as `hr@techcorp.demo`; open "Applications" | Alice's application visible |
| V4 | Accept Alice's application | Status → **accepted**; internship created; teacher notified |
| V5 | Log in as `marie.dupont@demo.test`; open "Agreements" | Pending agreement from TechCorp visible |
| V6 | Validate the agreement | Internship status → **active**; Alice and TechCorp notified |
| V7 | Log in as another student; apply to same offer; company rejects it | Status → **rejected**; student notified |
| V8 | Log in as student who applied; open "My applications"; click "Withdraw" on a pending application | Status → **withdrawn** |

---

## 4. Mission Monitoring (SRS MON-01..06)

| # | Steps | Expected result |
|---|-------|----------------|
| M1 | Log in as `alice.durand@demo.test`; open "My internship" | Dashboard shows parties, tasks, reports, progress |
| M2 | Log in as `hr@techcorp.demo`; open the internship; click "New task"; fill title + description + due date; save | Task appears in list with status **open** |
| M3 | Log in as Alice; open the task; click "Submit"; add a note; submit | Task status → **submitted**; supervisors notified |
| M4 | Log in as TechCorp; open the task; click "Validate" | Task status → **validated**; Alice notified |
| M5 | Log in as TechCorp; create another task; Alice submits; TechCorp clicks "Request changes" | Task status → **changes requested** |
| M6 | Log in as Alice; resubmit the changes-requested task | Task status → **submitted** again |
| M7 | Log in as Alice; open the internship dashboard; click "Submit report"; fill title, content, period; submit | Report appears with status **submitted** |
| M8 | Log in as `marie.dupont@demo.test` (teacher); open the internship; validate the report | Report status → **validated**; Alice notified |
| M9 | Teacher returns a report with feedback (request changes) | Report status → **changes_requested**; feedback visible |
| M10 | Verify progress bar on internship dashboard | % of validated tasks and reports shown |

---

## 5. Messaging (SRS MSG-01..03)

| # | Steps | Expected result |
|---|-------|----------------|
| MSG1 | Log in as Alice; open "Messages"; open the TechCorp thread | Thread shows all seeded messages in order |
| MSG2 | Send a new message | Message appears at the bottom; company/teacher get bell notification |
| MSG3 | Log in as TechCorp; open the thread | Alice's new message shown; unread count was > 0, now resets |
| MSG4 | Log in as teacher Marie; check messages | Thread accessible; can reply |
| MSG5 | Verify unread dot in topbar disappears after opening thread | Badge clears |

---

## 6. Evaluations (SRS EVAL-01..04)

| # | Steps | Expected result |
|---|-------|----------------|
| E1 | Log in as `hr@startuplab.demo`; open the completed internship; click "Evaluate" | Evaluation form shows the 5 criteria (1–5 scale) |
| E2 | Fill scores + comment; submit | Evaluation saved; student notified |
| E3 | Log in as teacher Marie; submit teacher evaluation for the completed internship | Teacher evaluation saved |
| E4 | Log in as `bob.lefebvre@demo.test`; open the completed internship | Summary section shows both evaluations and combined score |
| E5 | Attempt to submit a second evaluation for the same internship as the same role | Error: "An evaluation of this type has already been submitted" |

---

## 7. Notifications (SRS NOTIF-01)

| # | Steps | Expected result |
|---|-------|----------------|
| N1 | Perform any action that triggers a notification (e.g. accept application) | Bell badge increments for the recipient |
| N2 | Click the bell icon | Dropdown shows latest ≤ 8 notifications |
| N3 | Click a notification | Marks it read; navigates to the relevant route |
| N4 | Click "Mark all as read" | Badge clears; all items shown as read |
| N5 | Click "View all notifications" | Full paginated list at `/notifications` |

---

## 8. Administration

| # | Steps | Expected result |
|---|-------|----------------|
| AD1 | Log in as `admin@demo.test`; go to `http://127.0.0.1:8000/admin/` | Django admin with all models registered |
| AD2 | In Django admin → Users: list all users | All seeded users visible; roles correct |
| AD3 | `GET /api/v1/admin/stats/` with admin JWT | Returns counts by role/status |
| AD4 | `POST /api/v1/admin/assign-teacher/` with admin JWT; send `{"student_id": X, "teacher_id": Y}` | Teacher assigned; 200 OK |
| AD5 | Attempt the same admin endpoints with a non-admin token | 403 Forbidden |

---

## 9. Role boundaries (permission checks)

| # | Scenario | Expected result |
|---|----------|----------------|
| P1 | Student tries to access `/company/offers` | Redirect to own dashboard or 403 |
| P2 | Company tries to POST `/api/v1/offers/{id}/apply/` | 403 Forbidden |
| P3 | Teacher tries to accept an application | 403 Forbidden |
| P4 | Student tries to validate a task | 403 Forbidden |
| P5 | Unauthenticated request to any protected API endpoint | 401 Unauthorized |
| P6 | Company A tries to edit Company B's offer | 403 Forbidden |
| P7 | Student tries to read another student's internship | 403 Forbidden |

---

## 10. API documentation (Part C)

| # | Steps | Expected result |
|---|-------|----------------|
| D1 | Open `http://127.0.0.1:8000/api/v1/docs/` | Swagger UI loads; all endpoint groups visible |
| D2 | Open `http://127.0.0.1:8000/api/v1/redoc/` | ReDoc UI loads |
| D3 | In Swagger UI, click "Authorize"; enter `Bearer <access_token>` | Authenticated requests can be made from the UI |
| D4 | Try a protected endpoint (e.g. `GET /api/v1/me/`) from Swagger | Returns 200 with user data |

---

## 11. How to run automated tests

```bash
# Backend (from backend/)
python manage.py test              # all 162+ tests
python manage.py test core         # e2e flow only
python manage.py test accounts     # auth/accounts suite
# add app name for any individual suite

# Frontend (from frontend/)
npm run lint                       # ESLint
npm run build                      # TypeScript type check + production build
```

> Frontend test runner (Vitest/RTL) is not configured in v1.0.  
> Run `npm run lint` + `npm run build` for CI-equivalent checks.  
> Manual smoke test: follow the flows in sections 1–9 above against the running app.
