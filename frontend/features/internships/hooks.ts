"use client";

// React Query hooks for internships, tasks, and reports.

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { ApiError } from "@/lib/api/types";
import {
  createTask,
  getInternshipDashboard,
  listInternships,
  listReports,
  listTasks,
  requestReportChanges,
  requestTaskChanges,
  submitReport,
  submitTask,
  validateInternship,
  validateReport,
  validateTask,
} from "./api";
import type { SubmitReportInput, SubmitTaskInput } from "./types";

export const internshipKeys = {
  all: ["internships"] as const,
  list: ["internships", "list"] as const,
  dashboard: (id: number) => ["internships", "dashboard", id] as const,
  tasks: (id: number) => ["internships", id, "tasks"] as const,
  reports: (id: number) => ["internships", id, "reports"] as const,
};

const errMsg = (err: unknown, fallback: string) =>
  err instanceof ApiError ? err.message : fallback;

export function useInternships() {
  return useQuery({ queryKey: internshipKeys.list, queryFn: listInternships });
}

export function useInternshipDashboard(id: number) {
  return useQuery({
    queryKey: internshipKeys.dashboard(id),
    queryFn: () => getInternshipDashboard(id),
    enabled: Number.isFinite(id),
  });
}

export function useTasks(internshipId: number) {
  return useQuery({
    queryKey: internshipKeys.tasks(internshipId),
    queryFn: () => listTasks(internshipId),
    enabled: Number.isFinite(internshipId),
  });
}

export function useReports(internshipId: number) {
  return useQuery({
    queryKey: internshipKeys.reports(internshipId),
    queryFn: () => listReports(internshipId),
    enabled: Number.isFinite(internshipId),
  });
}

// One place to refresh everything tied to an internship after a mutation.
function useInvalidateInternships() {
  const queryClient = useQueryClient();
  return () =>
    queryClient.invalidateQueries({ queryKey: internshipKeys.all });
}

export function useValidateInternship() {
  const invalidate = useInvalidateInternships();
  return useMutation({
    mutationFn: (id: number) => validateInternship(id),
    onSuccess: () => {
      invalidate();
      toast.success("Agreement validated — internship is now active");
    },
    onError: (err) =>
      toast.error(errMsg(err, "Could not validate the agreement.")),
  });
}

export function useCreateTask(internshipId: number) {
  const invalidate = useInvalidateInternships();
  return useMutation({
    mutationFn: (input: Parameters<typeof createTask>[1]) =>
      createTask(internshipId, input),
    onSuccess: () => {
      invalidate();
      toast.success("Task created");
    },
    onError: (err) => toast.error(errMsg(err, "Could not create the task.")),
  });
}

export function useSubmitTask() {
  const invalidate = useInvalidateInternships();
  return useMutation({
    mutationFn: ({ taskId, ...input }: SubmitTaskInput & { taskId: number }) =>
      submitTask(taskId, input),
    onSuccess: () => {
      invalidate();
      toast.success("Task submitted");
    },
    onError: (err) => toast.error(errMsg(err, "Could not submit the task.")),
  });
}

export function useValidateTask() {
  const invalidate = useInvalidateInternships();
  return useMutation({
    mutationFn: (taskId: number) => validateTask(taskId),
    onSuccess: () => {
      invalidate();
      toast.success("Task validated");
    },
    onError: (err) => toast.error(errMsg(err, "Could not validate the task.")),
  });
}

export function useRequestTaskChanges() {
  const invalidate = useInvalidateInternships();
  return useMutation({
    mutationFn: (taskId: number) => requestTaskChanges(taskId),
    onSuccess: () => {
      invalidate();
      toast.success("Changes requested");
    },
    onError: (err) => toast.error(errMsg(err, "Could not request changes.")),
  });
}

export function useSubmitReport(internshipId: number) {
  const invalidate = useInvalidateInternships();
  return useMutation({
    mutationFn: (input: SubmitReportInput) => submitReport(internshipId, input),
    onSuccess: () => {
      invalidate();
      toast.success("Report submitted");
    },
    onError: (err) => toast.error(errMsg(err, "Could not submit the report.")),
  });
}

export function useValidateReport() {
  const invalidate = useInvalidateInternships();
  return useMutation({
    mutationFn: (reportId: number) => validateReport(reportId),
    onSuccess: () => {
      invalidate();
      toast.success("Report validated");
    },
    onError: (err) => toast.error(errMsg(err, "Could not validate the report.")),
  });
}

export function useRequestReportChanges() {
  const invalidate = useInvalidateInternships();
  return useMutation({
    mutationFn: ({ reportId, feedback }: { reportId: number; feedback: string }) =>
      requestReportChanges(reportId, feedback),
    onSuccess: () => {
      invalidate();
      toast.success("Changes requested");
    },
    onError: (err) => toast.error(errMsg(err, "Could not request changes.")),
  });
}
