"""Evaluation criteria configuration — the single source of truth.

Returned to the frontend in the evaluations payload so the forms/cards render
data-driven (no duplicated criteria list on the client).
"""

SCORE_MIN = 1
SCORE_MAX = 10

# Evaluations are read-only once submitted. Flip on (and add an edit endpoint)
# only if an edit window is ever required.
EVALUATION_EDIT_ENABLED = False


def _criterion(key: str, label: str) -> dict:
    return {"key": key, "label": label, "min": SCORE_MIN, "max": SCORE_MAX}


# Company and teacher assess the student on the same set.
COMPANY_TEACHER_CRITERIA = [
    _criterion("technical_skills", "Technical skills"),
    _criterion("autonomy", "Autonomy"),
    _criterion("communication", "Communication"),
    _criterion("professionalism", "Professionalism"),
    _criterion("overall", "Overall"),
]

# The student rates the internship experience (optional).
STUDENT_CRITERIA = [
    _criterion("supervision", "Supervision"),
    _criterion("learning", "Learning"),
    _criterion("environment", "Work environment"),
]

# evaluator_type -> its criteria list.
CRITERIA_BY_TYPE = {
    "company": COMPANY_TEACHER_CRITERIA,
    "teacher": COMPANY_TEACHER_CRITERIA,
    "student": STUDENT_CRITERIA,
}


def criteria_keys(evaluator_type: str) -> set[str]:
    return {c["key"] for c in CRITERIA_BY_TYPE[evaluator_type]}
