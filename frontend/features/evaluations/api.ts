// Typed API calls for evaluations via the central client.

import { apiGet, apiPost } from "@/lib/api/client";
import type {
  Evaluation,
  EvaluationsPayload,
  SubmitEvaluationInput,
} from "./types";

/** GET /internships/{id}/evaluations/ — evaluations + summary + criteria. */
export function getInternshipEvaluations(
  internshipId: number,
): Promise<EvaluationsPayload> {
  return apiGet<EvaluationsPayload>(
    `/internships/${internshipId}/evaluations/`,
  );
}

/** POST /internships/{id}/evaluations/ — evaluator_type inferred from role. */
export function submitEvaluation(
  internshipId: number,
  input: SubmitEvaluationInput,
): Promise<Evaluation> {
  return apiPost<Evaluation>(
    `/internships/${internshipId}/evaluations/`,
    input,
  );
}

/** GET /evaluations/{id}/ — read-only detail. */
export function getEvaluation(id: number): Promise<Evaluation> {
  return apiGet<Evaluation>(`/evaluations/${id}/`);
}
