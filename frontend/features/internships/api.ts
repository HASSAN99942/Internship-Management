// Typed API calls for internships, tasks, and reports via the central client.

import { apiGet, apiPatch, apiPost, apiUpload } from "@/lib/api/client";
import type { Paginated } from "@/lib/api/types";
import type {
  CreateTaskInput,
  Internship,
  InternshipDashboard,
  Report,
  SubmitReportInput,
  SubmitTaskInput,
  Task,
} from "./types";

/** GET /internships/ — internships visible to the caller (role-scoped). */
export function listInternships(): Promise<Paginated<Internship>> {
  return apiGet<Paginated<Internship>>("/internships/");
}

/** GET /internships/{id}/ — dashboard aggregate (parties/tasks/reports/progress). */
export function getInternshipDashboard(
  id: number,
): Promise<InternshipDashboard> {
  return apiGet<InternshipDashboard>(`/internships/${id}/`);
}

export function validateInternship(id: number): Promise<Internship> {
  return apiPost<Internship>(`/internships/${id}/validate/`);
}

// --- tasks --- //
export function listTasks(internshipId: number): Promise<Task[]> {
  return apiGet<Task[]>(`/internships/${internshipId}/tasks/`);
}

export function createTask(
  internshipId: number,
  input: CreateTaskInput,
): Promise<Task> {
  return apiPost<Task>(`/internships/${internshipId}/tasks/`, input);
}

export function getTask(id: number): Promise<Task> {
  return apiGet<Task>(`/tasks/${id}/`);
}

export function updateTask(
  id: number,
  input: Partial<CreateTaskInput>,
): Promise<Task> {
  return apiPatch<Task>(`/tasks/${id}/`, input);
}

export function submitTask(id: number, input: SubmitTaskInput): Promise<Task> {
  const form = new FormData();
  form.append("submission_note", input.submission_note ?? "");
  if (input.submission_file) form.append("submission_file", input.submission_file);
  return apiUpload<Task>(`/tasks/${id}/submit/`, form);
}

export function validateTask(id: number): Promise<Task> {
  return apiPost<Task>(`/tasks/${id}/validate/`);
}

export function requestTaskChanges(id: number): Promise<Task> {
  return apiPost<Task>(`/tasks/${id}/request-changes/`);
}

// --- reports --- //
export function listReports(internshipId: number): Promise<Report[]> {
  return apiGet<Report[]>(`/internships/${internshipId}/reports/`);
}

export function submitReport(
  internshipId: number,
  input: SubmitReportInput,
): Promise<Report> {
  const form = new FormData();
  form.append("title", input.title);
  form.append("content", input.content);
  form.append("period", input.period);
  if (input.file) form.append("file", input.file);
  return apiUpload<Report>(`/internships/${internshipId}/reports/`, form);
}

export function getReport(id: number): Promise<Report> {
  return apiGet<Report>(`/reports/${id}/`);
}

export function validateReport(id: number): Promise<Report> {
  return apiPost<Report>(`/reports/${id}/validate/`);
}

export function requestReportChanges(
  id: number,
  feedback: string,
): Promise<Report> {
  return apiPost<Report>(`/reports/${id}/request-changes/`, { feedback });
}
