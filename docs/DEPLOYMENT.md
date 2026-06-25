# Deployment Guide

## Local development

### Prerequisites
- Python 3.11+
- Node.js 18+
- Git

### 1. Clone the repository

```bash
git clone <repo-url>
cd internship
```

### 2. Backend setup

```bash
cd backend

# Create and activate virtual environment
python -m venv venv
# Windows (PowerShell):
venv\Scripts\Activate.ps1
# macOS / Linux:
# source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create your local environment file
copy .env.example .env          # Windows
# cp .env.example .env          # macOS / Linux

# Edit .env: at minimum set a proper SECRET_KEY (see the file for instructions)

# Run database migrations
python manage.py migrate

# (Optional) Load demo data
python manage.py seed

# Start the development server
python manage.py runserver
```

API available at: `http://127.0.0.1:8000`  
Health check: `GET http://127.0.0.1:8000/api/v1/health/` → `{"status": "ok"}`  
API docs (Swagger): `http://127.0.0.1:8000/api/v1/docs/`

### 3. Frontend setup

```bash
cd frontend

# Install dependencies
npm install

# Create your local environment file
copy .env.local.example .env.local    # Windows
# cp .env.local.example .env.local    # macOS / Linux

# Start the development server
npm run dev
```

App available at: `http://localhost:3000`

> Start the backend first so the frontend health check can reach it.

---

## Running tests

```bash
# Backend (from backend/ with venv active)
python manage.py test

# Frontend (from frontend/)
npm run lint          # ESLint
npm run build         # TypeScript type check + production build
```

---

## Seed data

```bash
# From backend/ with venv active:

python manage.py seed           # Idempotent — skips if data already exists
python manage.py seed --flush   # Wipe all data first, then reseed (for demos)
```

The command prints all demo credentials when it finishes. Default password: `Demo1234!`  
Override via environment variable: `SEED_PASSWORD=MyPassword python manage.py seed`

---

## Production deployment

### Environment variables (backend)

| Variable | Required | Description |
|---|:---:|---|
| `SECRET_KEY` | ✓ | Long random string — use `python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"` |
| `DEBUG` | ✓ | Must be `False` in production |
| `ALLOWED_HOSTS` | ✓ | Comma-separated list: `myapp.onrender.com,www.myapp.com` |
| `DATABASE_URL` | ✓ | PostgreSQL connection string: `postgres://user:pass@host:5432/db` |
| `CORS_ALLOWED_ORIGINS` | ✓ | Comma-separated frontend origin(s): `https://myapp.vercel.app` |
| `ACCESS_TOKEN_LIFETIME_MIN` | – | Default: 15 (minutes) |
| `REFRESH_TOKEN_LIFETIME_DAYS` | – | Default: 7 (days) |
| `EMAIL_BACKEND` | – | Set to `django.core.mail.backends.smtp.EmailBackend` for real email |
| `EMAIL_HOST` | – | SMTP host (e.g. `smtp.sendgrid.net`) |
| `EMAIL_PORT` | – | Default: 587 |
| `EMAIL_HOST_USER` | – | SMTP username |
| `EMAIL_HOST_PASSWORD` | – | SMTP password / API key |
| `DEFAULT_FROM_EMAIL` | – | Default: `noreply@internship.local` |
| `SECURE_SSL_REDIRECT` | – | Default: `True` when `DEBUG=False` — set `False` if host terminates SSL upstream |

### Environment variables (frontend)

| Variable | Required | Description |
|---|:---:|---|
| `NEXT_PUBLIC_API_BASE_URL` | ✓ | Public URL of the deployed backend, e.g. `https://api.myapp.com` |

### Database: SQLite → PostgreSQL

SQLite is used for development. All data access goes through the Django ORM, so switching to PostgreSQL requires **no code changes**:

1. Provision a PostgreSQL database (e.g. Render Postgres, Supabase, Railway).
2. Set `DATABASE_URL=postgres://user:pass@host:5432/dbname` in your production environment.
3. Uncomment `psycopg2-binary` in `requirements.txt` (or install `psycopg2`).
4. Run migrations on the new database: `python manage.py migrate`.

### Backend deployment (example: Render)

1. Push your code to GitHub.
2. Create a new **Web Service** on Render, pointing at the `backend/` directory.
3. Set the build command:
   ```
   pip install -r requirements.txt && python manage.py migrate && python manage.py collectstatic --no-input
   ```
4. Set the start command:
   ```
   gunicorn config.wsgi:application
   ```
   (Install `gunicorn` — add it to `requirements.txt`.)
5. Add all required environment variables in the Render dashboard.
6. (Optional) Run `python manage.py seed` once via the Render shell for demo data.

### Frontend deployment (Vercel)

1. Push your code to GitHub.
2. Import the repository in Vercel; set the **Root Directory** to `frontend`.
3. Add the environment variable `NEXT_PUBLIC_API_BASE_URL` pointing at your deployed backend URL.
4. Vercel automatically runs `npm run build` on every push.

### Static files

Static files (Django admin CSS, drf-spectacular Swagger UI assets) are collected with:

```bash
python manage.py collectstatic --no-input
```

WhiteNoise (already in `requirements.txt` and configured in `settings.py`) serves them directly from Django with compression and long-lived caching headers — no separate Nginx/CDN required for the admin UI.

### CORS

Ensure `CORS_ALLOWED_ORIGINS` on the backend includes the exact origin of your deployed frontend (e.g. `https://myapp.vercel.app`). Do not use `CORS_ALLOW_ALL_ORIGINS=True` in production.

### Media files (user uploads)

CV and report file uploads are stored in `MEDIA_ROOT` (local filesystem in development). For production:

- On Render/VPS: mount a persistent disk at `MEDIA_ROOT`.
- For a more scalable setup: replace `FileSystemStorage` with a cloud storage backend (e.g. `django-storages` + AWS S3 / Cloudflare R2).
