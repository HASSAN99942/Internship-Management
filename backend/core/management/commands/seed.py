"""
Seed the database with a self-consistent demo dataset.

Usage:
    python manage.py seed            # idempotent — skips if data exists
    python manage.py seed --flush    # wipe all data first, then re-seed

The password for all demo accounts is read from the SEED_PASSWORD environment
variable (default: Demo1234!).  Credentials are printed at the end.
"""

import os
from datetime import date, timedelta

from django.core.management import call_command
from django.core.management.base import BaseCommand
from django.db import transaction

from accounts.models import StudentProfile, User
from accounts.services import assign_teacher, register_user
from applications.services import (
    accept_application,
    apply_to_offer,
    reject_application,
    withdraw_application,
)
from evaluations.models import Evaluation
from evaluations.services import submit_evaluation
from internships.models import Internship
from internships.services import (
    create_task,
    request_report_changes,
    request_task_changes,
    submit_report,
    submit_task,
    validate_internship,
    validate_report,
    validate_task,
)
from messaging.models import MessageThread
from messaging.services import send_message
from offers.services import close_offer, create_offer, publish_offer


class Command(BaseCommand):
    help = "Populate the database with realistic demo data."

    def add_arguments(self, parser):
        parser.add_argument(
            "--flush",
            action="store_true",
            help="Flush all existing data before seeding (clean slate).",
        )

    def handle(self, *args, **options):
        if options["flush"]:
            self.stdout.write("Flushing all data…")
            call_command("flush", "--no-input", verbosity=0)
            self.stdout.write(self.style.WARNING("  Database flushed."))

        # Skip if already seeded (idempotent without --flush)
        if User.objects.filter(email="admin@demo.test").exists():
            self.stdout.write(
                self.style.WARNING(
                    "Seed data already present. Use --flush to re-seed."
                )
            )
            self._print_credentials(os.environ.get("SEED_PASSWORD", "Demo1234!"))
            return

        pw = os.environ.get("SEED_PASSWORD", "Demo1234!")
        today = date.today()

        with transaction.atomic():
            self._seed(pw, today)

        self.stdout.write(self.style.SUCCESS("\nSeed complete!"))
        self._print_credentials(pw)

    # ---------------------------------------------------------------------- #
    # Main seed logic (all inside one atomic block)                           #
    # ---------------------------------------------------------------------- #
    def _seed(self, pw: str, today: date) -> None:
        # ------------------------------------------------------------------ #
        # 1. Users                                                            #
        # ------------------------------------------------------------------ #
        self.stdout.write("  Creating users…")

        admin = User.objects.create_user(
            email="admin@demo.test",
            password=pw,
            role="admin",
            first_name="Admin",
            last_name="Platform",
            is_staff=True,
            is_superuser=True,
        )

        teacher1 = register_user(
            email="marie.dupont@demo.test",
            password=pw,
            role="teacher",
            first_name="Marie",
            last_name="Dupont",
            profile={
                "department": "Computer Science",
                "title": "Professor",
                "phone": "+33 1 00 00 00 01",
            },
        )
        teacher2 = register_user(
            email="jean.martin@demo.test",
            password=pw,
            role="teacher",
            first_name="Jean",
            last_name="Martin",
            profile={
                "department": "Business & Finance",
                "title": "Associate Professor",
                "phone": "+33 1 00 00 00 02",
            },
        )

        company1 = register_user(
            email="hr@techcorp.demo",
            password=pw,
            role="company",
            first_name="TechCorp",
            last_name="HR",
            profile={
                "company_name": "TechCorp SAS",
                "sector": "Software Development",
                "website": "https://techcorp.example.com",
                "address": "15 rue de la Paix, Paris 75001",
                "description": "Leading French software company specialising in cloud-native backend systems.",
                "contact_phone": "+33 2 00 00 00 01",
            },
        )
        company2 = register_user(
            email="hr@startuplab.demo",
            password=pw,
            role="company",
            first_name="StartupLab",
            last_name="HR",
            profile={
                "company_name": "StartupLab",
                "sector": "FinTech",
                "website": "https://startuplab.example.com",
                "address": "8 quai Saint-Antoine, Lyon 69002",
                "description": "Early-stage FinTech startup building payment infrastructure for SMEs.",
                "contact_phone": "+33 2 00 00 00 02",
            },
        )
        company3 = register_user(
            email="hr@innovate.demo",
            password=pw,
            role="company",
            first_name="Innovate",
            last_name="HR",
            profile={
                "company_name": "Innovate & Co",
                "sector": "Data Science & Consulting",
                "website": "https://innovate.example.com",
                "address": "22 cours du Chapeau Rouge, Bordeaux 33000",
                "description": "Data-driven consulting firm helping mid-market businesses leverage ML/AI.",
                "contact_phone": "+33 2 00 00 00 03",
            },
        )

        student1 = register_user(
            email="alice.durand@demo.test",
            password=pw,
            role="student",
            first_name="Alice",
            last_name="Durand",
            profile={
                "school": "EPITECH Paris",
                "program": "Software Engineering",
                "level": "M1",
                "phone": "+33 6 00 00 00 01",
            },
        )
        student2 = register_user(
            email="bob.lefebvre@demo.test",
            password=pw,
            role="student",
            first_name="Bob",
            last_name="Lefèvre",
            profile={
                "school": "HEC Paris",
                "program": "Finance & Data",
                "level": "M2",
                "phone": "+33 6 00 00 00 02",
            },
        )
        student3 = register_user(
            email="carol.moreau@demo.test",
            password=pw,
            role="student",
            first_name="Carol",
            last_name="Moreau",
            profile={
                "school": "Centrale Lyon",
                "program": "Data Science",
                "level": "L3",
                "phone": "+33 6 00 00 00 03",
            },
        )

        # ------------------------------------------------------------------ #
        # 2. Teacher → student assignments                                    #
        # ------------------------------------------------------------------ #
        self.stdout.write("  Assigning supervisors…")

        for student_user, teacher_user in [
            (student1, teacher1),
            (student2, teacher1),
            (student3, teacher2),
        ]:
            profile = StudentProfile.objects.get(user=student_user)
            assign_teacher(profile=profile, teacher_user=teacher_user, by_user=admin)

        # Refresh student objects so the student_profile reverse-relation cache
        # (populated during register_user) doesn't hide the teacher we just set.
        student1 = User.objects.get(id=student1.id)
        student2 = User.objects.get(id=student2.id)
        student3 = User.objects.get(id=student3.id)

        # ------------------------------------------------------------------ #
        # 3. Offers                                                           #
        # ------------------------------------------------------------------ #
        self.stdout.write("  Creating offers…")

        # company1 — TechCorp
        offer_backend = publish_offer(
            create_offer(
                company_user=company1,
                data={
                    "title": "Backend Python Developer",
                    "description": (
                        "Join our backend team to design and build REST APIs "
                        "using Python/Django. You will work on our cloud-native "
                        "platform serving thousands of daily users."
                    ),
                    "skills": "Python, Django, REST API, SQL, Git",
                    "location": "Paris (hybrid)",
                    "duration_weeks": 24,
                    "start_date": today + timedelta(weeks=2),
                    "positions": 2,
                },
            )
        )
        offer_devops = publish_offer(
            create_offer(
                company_user=company1,
                data={
                    "title": "DevOps / Platform Engineer",
                    "description": (
                        "Help us build and maintain our CI/CD pipelines, "
                        "Kubernetes clusters, and monitoring stack."
                    ),
                    "skills": "Docker, Kubernetes, CI/CD, Linux, Python",
                    "location": "Paris (on-site)",
                    "duration_weeks": 16,
                    "start_date": today + timedelta(weeks=4),
                    "positions": 1,
                },
            )
        )

        # company2 — StartupLab
        offer_fintech = publish_offer(
            create_offer(
                company_user=company2,
                data={
                    "title": "FinTech Data Analyst",
                    "description": (
                        "Analyse payment transaction data to detect anomalies "
                        "and build dashboards for our product team."
                    ),
                    "skills": "SQL, Python, Pandas, Power BI",
                    "location": "Lyon (hybrid)",
                    "duration_weeks": 20,
                    "start_date": today - timedelta(weeks=10),
                    "positions": 1,
                },
            )
        )
        _offer_frontend_draft = create_offer(
            company_user=company2,
            data={
                "title": "Frontend React Developer",
                "description": "Build our next-gen customer-facing dashboard with React and TypeScript.",
                "skills": "React, TypeScript, Tailwind CSS",
                "location": "Remote",
                "duration_weeks": 16,
                "start_date": today + timedelta(weeks=8),
                "positions": 1,
            },
        )  # stays as draft

        # company3 — Innovate & Co
        offer_ml = publish_offer(
            create_offer(
                company_user=company3,
                data={
                    "title": "Machine Learning Engineer",
                    "description": (
                        "Develop predictive models for client churn analysis "
                        "using scikit-learn and PyTorch."
                    ),
                    "skills": "Python, scikit-learn, PyTorch, SQL",
                    "location": "Bordeaux (on-site)",
                    "duration_weeks": 20,
                    "start_date": today + timedelta(weeks=3),
                    "positions": 2,
                },
            )
        )
        offer_dataviz = close_offer(
            publish_offer(
                create_offer(
                    company_user=company3,
                    data={
                        "title": "Data Visualisation Specialist",
                        "description": "Create compelling dashboards and reports with Tableau and D3.js.",
                        "skills": "Tableau, D3.js, SQL, Python",
                        "location": "Bordeaux (hybrid)",
                        "duration_weeks": 12,
                        "start_date": today - timedelta(weeks=20),
                        "positions": 1,
                    },
                )
            )
        )  # now closed

        # ------------------------------------------------------------------ #
        # 4. Applications (various statuses)                                  #
        # ------------------------------------------------------------------ #
        self.stdout.write("  Creating applications…")

        # alice → backend (will be accepted → ACTIVE internship)
        app_alice_backend = apply_to_offer(
            student=student1,
            offer=offer_backend,
            data={"cover_message": (
                "I am very interested in your Backend Python Developer position. "
                "My studies at EPITECH have given me a solid grounding in Python "
                "and REST API design, and I am eager to apply these skills in a "
                "real production environment."
            )},
        )

        # bob → fintech (will be accepted → COMPLETED internship)
        app_bob_fintech = apply_to_offer(
            student=student2,
            offer=offer_fintech,
            data={"cover_message": (
                "As an M2 Finance & Data student at HEC, I am excited about "
                "the opportunity to work on payment analytics at StartupLab. "
                "I have strong SQL and Python skills and experience with Power BI."
            )},
        )

        # carol → ml (will be rejected)
        app_carol_ml = apply_to_offer(
            student=student3,
            offer=offer_ml,
            data={"cover_message": (
                "I am a Data Science student at Centrale Lyon looking for an "
                "opportunity to apply my ML knowledge in a consulting environment."
            )},
        )

        # carol → devops (pending — still awaiting company decision)
        _app_carol_devops = apply_to_offer(
            student=student3,
            offer=offer_devops,
            data={"cover_message": "I am interested in the DevOps internship at TechCorp."},
        )

        # alice → ml (will be withdrawn by alice)
        app_alice_ml = apply_to_offer(
            student=student1,
            offer=offer_ml,
            data={"cover_message": "Applying as backup while waiting to hear from TechCorp."},
        )

        # Decisions
        reject_application(application=app_carol_ml)
        withdraw_application(application=app_alice_ml, by_user=student1)

        # ------------------------------------------------------------------ #
        # 5. ACTIVE internship — alice @ TechCorp                            #
        # ------------------------------------------------------------------ #
        self.stdout.write("  Building ACTIVE internship (Alice @ TechCorp)…")

        active_internship = accept_application(application=app_alice_backend)
        validate_internship(internship=active_internship, by_user=teacher1)

        # Tasks
        task_env = create_task(
            internship=active_internship,
            by_user=company1,
            data={
                "title": "Set up development environment",
                "description": "Install all required tools: Python, Docker, Git, and connect to staging.",
                "due_date": today - timedelta(days=14),
            },
        )
        submit_task(task=task_env, note="All tools installed. Docker running. Connected to staging VPN.")
        validate_task(task=task_env)  # → VALIDATED

        task_api = create_task(
            internship=active_internship,
            by_user=company1,
            data={
                "title": "Implement REST API endpoints for user profiles",
                "description": "Add CRUD endpoints for the user profile resource as per the API spec.",
                "due_date": today + timedelta(days=7),
            },
        )
        submit_task(task=task_api, note="Endpoints implemented. Tests passing. PR #42 ready for review.")
        # → SUBMITTED (awaiting validation)

        task_tests = create_task(
            internship=active_internship,
            by_user=teacher1,
            data={
                "title": "Write integration tests for the API",
                "description": "Cover all happy paths and at least two error/permission cases per endpoint.",
                "due_date": today + timedelta(days=5),
            },
        )
        submit_task(task=task_tests, note="Tests written. Coverage at 72%.")
        request_task_changes(task=task_tests)  # → CHANGES_REQUESTED

        _task_review = create_task(
            internship=active_internship,
            by_user=company1,
            data={
                "title": "Code review and documentation",
                "description": "Review peers' PRs and update the API docs in the wiki.",
                "due_date": today + timedelta(days=21),
            },
        )  # → OPEN

        # Reports
        report1 = submit_report(
            internship=active_internship,
            by_student=student1,
            data={
                "title": "Week 1 Progress Report",
                "content": (
                    "This week I focused on onboarding: setting up the dev environment, "
                    "reading the codebase, and attending team stand-ups. I have a good "
                    "understanding of the architecture and am ready to start coding."
                ),
                "period": "Week 1",
            },
        )
        validate_report(report=report1)  # → VALIDATED

        report2 = submit_report(
            internship=active_internship,
            by_student=student1,
            data={
                "title": "Week 2 Progress Report",
                "content": (
                    "Implemented the user-profile endpoints. Ran into a few edge cases "
                    "with the serializer but resolved them. Tests passing at 72%."
                ),
                "period": "Week 2",
            },
        )
        request_report_changes(
            report=report2,
            feedback="Good progress, but the report is too brief. Please add a section "
                     "on challenges encountered and how you resolved them.",
        )  # → CHANGES_REQUESTED

        _report3 = submit_report(
            internship=active_internship,
            by_student=student1,
            data={
                "title": "Week 3 Progress Report",
                "content": (
                    "Revised week 2 report and increased test coverage to 85%. "
                    "Started working on the code review tasks assigned by my supervisor."
                ),
                "period": "Week 3",
            },
        )  # → SUBMITTED (awaiting validation)

        # Messages
        thread_active: MessageThread = MessageThread.objects.get(internship=active_internship)
        send_message(thread=thread_active, sender=student1, body="Hello everyone! I've just started my onboarding. Very excited to be here at TechCorp!")
        send_message(thread=thread_active, sender=company1, body="Welcome Alice! Don't hesitate to ask if you have any questions. Your first task has been assigned.")
        send_message(thread=thread_active, sender=teacher1, body="Hi Alice, I'm Marie, your academic supervisor. Please submit your weekly reports on time. Good luck!")
        send_message(thread=thread_active, sender=student1, body="Thank you both! I've set up my environment and started reading the API spec. I'll have the first report in by Friday.")
        send_message(thread=thread_active, sender=company1, body="Great. Make sure to join the Tuesday stand-up at 9:30 AM. The Zoom link is in your welcome email.")

        # ------------------------------------------------------------------ #
        # 6. COMPLETED internship — bob @ StartupLab                         #
        # ------------------------------------------------------------------ #
        self.stdout.write("  Building COMPLETED internship (Bob @ StartupLab)…")

        completed_internship = accept_application(application=app_bob_fintech)
        validate_internship(internship=completed_internship, by_user=teacher1)

        # Tasks (all validated)
        task_c1 = create_task(
            internship=completed_internship,
            by_user=company2,
            data={
                "title": "Explore transaction dataset and produce EDA report",
                "description": "Load the Q1 dataset and produce an exploratory data analysis notebook.",
                "due_date": today - timedelta(weeks=8),
            },
        )
        submit_task(task=task_c1, note="EDA notebook complete. Key findings documented.")
        validate_task(task=task_c1)

        task_c2 = create_task(
            internship=completed_internship,
            by_user=company2,
            data={
                "title": "Build anomaly detection pipeline",
                "description": "Implement and evaluate at least two anomaly detection algorithms.",
                "due_date": today - timedelta(weeks=4),
            },
        )
        submit_task(task=task_c2, note="Isolation Forest and DBSCAN implemented. Results summarised in /reports/anomaly_v2.pdf.")
        validate_task(task=task_c2)

        # Reports (all validated)
        rep_c1 = submit_report(
            internship=completed_internship,
            by_student=student2,
            data={
                "title": "Month 1 Report — Data Exploration",
                "content": (
                    "Completed onboarding and deep-dived into the transaction dataset. "
                    "Identified data quality issues and cleaned 12% of records. "
                    "Produced an EDA notebook summarising distributions and key correlations."
                ),
                "period": "Month 1",
            },
        )
        validate_report(report=rep_c1)

        rep_c2 = submit_report(
            internship=completed_internship,
            by_student=student2,
            data={
                "title": "Month 2 Report — Anomaly Detection",
                "content": (
                    "Implemented Isolation Forest and DBSCAN pipelines. "
                    "Precision/recall comparison shows Isolation Forest superior on our data. "
                    "Model integrated into the analytics dashboard."
                ),
                "period": "Month 2",
            },
        )
        validate_report(report=rep_c2)

        # Messages
        thread_completed: MessageThread = MessageThread.objects.get(internship=completed_internship)
        send_message(thread=thread_completed, sender=student2, body="Hi team, Bob here. Looking forward to working with StartupLab on the FinTech analytics project!")
        send_message(thread=thread_completed, sender=company2, body="Welcome Bob! Your first task is to explore the Q1 transaction dataset. Access details sent to your email.")
        send_message(thread=thread_completed, sender=teacher1, body="Bob, make sure your monthly reports align with the academic guidelines I shared. Let me know if you need support.")
        send_message(thread=thread_completed, sender=student2, body="Internship complete! It was a great experience. Thank you both for your support and mentoring.")
        send_message(thread=thread_completed, sender=company2, body="You were a pleasure to work with, Bob. We've submitted our evaluation — best of luck with your studies!")

        # Evaluations
        submit_evaluation(
            internship=completed_internship,
            evaluator=company2,
            evaluator_type=Evaluation.EvaluatorType.COMPANY,
            scores={
                "technical_skills": 9,
                "communication": 8,
                "initiative": 8,
                "reliability": 9,
            },
            comment=(
                "Bob demonstrated strong analytical skills and a professional attitude throughout "
                "the internship. He delivered high-quality work on time and integrated seamlessly "
                "with the team. We would welcome him back."
            ),
        )
        submit_evaluation(
            internship=completed_internship,
            evaluator=teacher1,
            evaluator_type=Evaluation.EvaluatorType.TEACHER,
            scores={
                "academic_progress": 8,
                "report_quality": 9,
                "professional_behaviour": 8,
                "autonomy": 7,
            },
            comment=(
                "Bob produced excellent monthly reports that clearly connected his practical work "
                "to academic learning outcomes. He showed good autonomy and took feedback well."
            ),
        )

        # Mark internship as completed
        completed_internship.status = Internship.Status.COMPLETED
        completed_internship.save(update_fields=["status", "updated_at"])

    # ---------------------------------------------------------------------- #
    # Helpers                                                                 #
    # ---------------------------------------------------------------------- #
    def _print_credentials(self, password: str) -> None:
        sep = "-" * 60
        self.stdout.write(f"\n{sep}")
        self.stdout.write(self.style.SUCCESS("  DEMO CREDENTIALS"))
        self.stdout.write(f"  Password for all accounts:  {self.style.WARNING(password)}")
        self.stdout.write(sep)
        rows = [
            ("admin",   "admin@demo.test",           "Django admin + API"),
            ("teacher", "marie.dupont@demo.test",    "Alice & Bob's supervisor"),
            ("teacher", "jean.martin@demo.test",     "Carol's supervisor"),
            ("company", "hr@techcorp.demo",          "TechCorp (active internship)"),
            ("company", "hr@startuplab.demo",        "StartupLab (completed internship)"),
            ("company", "hr@innovate.demo",          "Innovate & Co (draft + closed offers)"),
            ("student", "alice.durand@demo.test",    "Active internship @ TechCorp"),
            ("student", "bob.lefebvre@demo.test",    "Completed internship @ StartupLab"),
            ("student", "carol.moreau@demo.test",    "Pending + rejected applications"),
        ]
        for role, email, note in rows:
            self.stdout.write(f"  [{role:7s}]  {email:35s}  {note}")
        self.stdout.write(sep)
        self.stdout.write("  API docs:  http://127.0.0.1:8000/api/v1/docs/")
        self.stdout.write("  Admin UI:  http://127.0.0.1:8000/admin/")
        self.stdout.write(f"{sep}\n")
