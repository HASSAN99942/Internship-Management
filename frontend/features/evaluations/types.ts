// Types for the evaluations feature. Mirrors the backend serializers.
// Criteria are delivered by the API (single source of truth), not hardcoded.

export type EvaluatorType = "company" | "teacher" | "student";

export interface Evaluator {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
}

export interface Criterion {
  key: string;
  label: string;
  min: number;
  max: number;
}

export interface Evaluation {
  id: number;
  internship: number;
  evaluator: Evaluator;
  evaluator_type: EvaluatorType;
  scores: Record<string, number>;
  comment: string;
  total_score: number;
  created_at: string;
}

export interface SummaryEntry {
  total_score: number;
  scores: Record<string, number>;
  comment: string;
}

export interface EvaluationSummary {
  company: SummaryEntry | null;
  teacher: SummaryEntry | null;
  student: SummaryEntry | null;
  combined: number | null;
}

/** GET /internships/{id}/evaluations/ aggregate. */
export interface EvaluationsPayload {
  criteria: Record<EvaluatorType, Criterion[]>;
  evaluations: Evaluation[];
  summary: EvaluationSummary;
}

export interface SubmitEvaluationInput {
  scores: Record<string, number>;
  comment?: string;
}
