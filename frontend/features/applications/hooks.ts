"use client";

// React Query hooks for applications. Mutations invalidate the lists they affect
// (applications + internships, since accept creates an internship) and toast.

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { ApiError } from "@/lib/api/types";
import {
  acceptApplication,
  applyToOffer,
  listApplications,
  rejectApplication,
  withdrawApplication,
} from "./api";
import type { ApplyInput } from "./types";

export const applicationKeys = {
  all: ["applications"] as const,
  list: ["applications", "list"] as const,
};

function toastError(err: unknown, fallback: string) {
  toast.error(err instanceof ApiError ? err.message : fallback);
}

export function useApplications(enabled = true) {
  return useQuery({
    queryKey: applicationKeys.list,
    queryFn: listApplications,
    enabled,
  });
}

function useInvalidateApplications() {
  const queryClient = useQueryClient();
  return () => {
    queryClient.invalidateQueries({ queryKey: applicationKeys.all });
    // Accept creates an internship; keep that list fresh too.
    queryClient.invalidateQueries({ queryKey: ["internships"] });
  };
}

export function useApplyToOffer(offerId: number) {
  const invalidate = useInvalidateApplications();
  return useMutation({
    mutationFn: (input: ApplyInput) => applyToOffer(offerId, input),
    onSuccess: () => {
      invalidate();
      toast.success("Application submitted");
    },
    onError: (err) => toastError(err, "Could not submit your application."),
  });
}

export function useAcceptApplication() {
  const invalidate = useInvalidateApplications();
  return useMutation({
    mutationFn: (id: number) => acceptApplication(id),
    onSuccess: () => {
      invalidate();
      toast.success("Application accepted — agreement created");
    },
    onError: (err) => toastError(err, "Could not accept the application."),
  });
}

export function useRejectApplication() {
  const invalidate = useInvalidateApplications();
  return useMutation({
    mutationFn: (id: number) => rejectApplication(id),
    onSuccess: () => {
      invalidate();
      toast.success("Application rejected");
    },
    onError: (err) => toastError(err, "Could not reject the application."),
  });
}

export function useWithdrawApplication() {
  const invalidate = useInvalidateApplications();
  return useMutation({
    mutationFn: (id: number) => withdrawApplication(id),
    onSuccess: () => {
      invalidate();
      toast.success("Application withdrawn");
    },
    onError: (err) => toastError(err, "Could not withdraw the application."),
  });
}
