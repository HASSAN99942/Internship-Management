"use client";

// React Query hooks for evaluations.

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { ApiError } from "@/lib/api/types";
import { internshipKeys } from "@/features/internships/hooks";
import {
  getEvaluation,
  getInternshipEvaluations,
  submitEvaluation,
} from "./api";
import type { SubmitEvaluationInput } from "./types";

export const evaluationKeys = {
  all: ["evaluations"] as const,
  forInternship: (id: number) => ["evaluations", "internship", id] as const,
  detail: (id: number) => ["evaluations", "detail", id] as const,
};

export function useInternshipEvaluations(internshipId: number) {
  return useQuery({
    queryKey: evaluationKeys.forInternship(internshipId),
    queryFn: () => getInternshipEvaluations(internshipId),
    enabled: Number.isFinite(internshipId),
  });
}

export function useEvaluation(id: number) {
  return useQuery({
    queryKey: evaluationKeys.detail(id),
    queryFn: () => getEvaluation(id),
    enabled: Number.isFinite(id),
  });
}

export function useSubmitEvaluation(internshipId: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (input: SubmitEvaluationInput) =>
      submitEvaluation(internshipId, input),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: evaluationKeys.forInternship(internshipId),
      });
      queryClient.invalidateQueries({
        queryKey: internshipKeys.dashboard(internshipId),
      });
      toast.success("Evaluation submitted");
    },
    onError: (err) =>
      toast.error(
        err instanceof ApiError ? err.message : "Could not submit the evaluation.",
      ),
  });
}
