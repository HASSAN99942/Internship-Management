"use client";

// React Query hooks for the supervision-request flow.

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { ApiError } from "@/lib/api/types";
import { meQueryKey } from "@/features/auth/hooks";
import { studentKeys } from "@/features/students/hooks";
import { useAuth } from "@/lib/auth/AuthContext";
import {
  acceptSupervisionRequest,
  cancelSupervisionRequest,
  createSupervisionRequest,
  listSupervisionRequests,
  rejectSupervisionRequest,
} from "./api";

export const supervisionKeys = {
  all: ["supervision"] as const,
  requests: ["supervision", "requests"] as const,
};

const errMsg = (err: unknown, fallback: string) =>
  err instanceof ApiError ? err.message : fallback;

export function useSupervisionRequests() {
  return useQuery({
    queryKey: supervisionKeys.requests,
    queryFn: listSupervisionRequests,
  });
}

// A supervision change can affect: the requests list, the teacher's roster,
// and the current user's profile (a student's assigned_teacher lives on /me).
function useSupervisionSideEffects() {
  const queryClient = useQueryClient();
  const { refreshUser } = useAuth();
  return async () => {
    await refreshUser();
    queryClient.invalidateQueries({ queryKey: supervisionKeys.requests });
    queryClient.invalidateQueries({ queryKey: studentKeys.all });
    queryClient.invalidateQueries({ queryKey: meQueryKey });
  };
}

export function useCreateSupervisionRequest() {
  const onChange = useSupervisionSideEffects();
  return useMutation({
    mutationFn: (targetId: number) => createSupervisionRequest(targetId),
    onSuccess: () => {
      void onChange();
      toast.success("Supervision request sent");
    },
    onError: (err) => toast.error(errMsg(err, "Could not send the request.")),
  });
}

export function useAcceptSupervisionRequest() {
  const onChange = useSupervisionSideEffects();
  return useMutation({
    mutationFn: (id: number) => acceptSupervisionRequest(id),
    onSuccess: () => {
      void onChange();
      toast.success("Supervision accepted");
    },
    onError: (err) => toast.error(errMsg(err, "Could not accept the request.")),
  });
}

export function useRejectSupervisionRequest() {
  const onChange = useSupervisionSideEffects();
  return useMutation({
    mutationFn: (id: number) => rejectSupervisionRequest(id),
    onSuccess: () => {
      void onChange();
      toast.success("Request rejected");
    },
    onError: (err) => toast.error(errMsg(err, "Could not reject the request.")),
  });
}

export function useCancelSupervisionRequest() {
  const onChange = useSupervisionSideEffects();
  return useMutation({
    mutationFn: (id: number) => cancelSupervisionRequest(id),
    onSuccess: () => {
      void onChange();
      toast.success("Request cancelled");
    },
    onError: (err) => toast.error(errMsg(err, "Could not cancel the request.")),
  });
}
