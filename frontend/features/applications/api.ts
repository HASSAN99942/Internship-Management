// Typed API calls for applications via the central client.

import { apiGet, apiPost, apiUpload } from "@/lib/api/client";
import type { Paginated } from "@/lib/api/types";
import type { Application, ApplyInput } from "./types";

/** POST /offers/{id}/apply/ — multipart (cover_message + optional cv_file). */
export function applyToOffer(
  offerId: number,
  input: ApplyInput,
): Promise<Application> {
  const form = new FormData();
  form.append("cover_message", input.cover_message);
  if (input.cv_file) form.append("cv_file", input.cv_file);
  return apiUpload<Application>(`/offers/${offerId}/apply/`, form);
}

/** GET /applications/ — role-scoped (student=own, company=received). */
export function listApplications(): Promise<Paginated<Application>> {
  return apiGet<Paginated<Application>>("/applications/");
}

export function getApplication(id: number): Promise<Application> {
  return apiGet<Application>(`/applications/${id}/`);
}

export function acceptApplication(id: number): Promise<Application> {
  return apiPost<Application>(`/applications/${id}/accept/`);
}

export function rejectApplication(id: number): Promise<Application> {
  return apiPost<Application>(`/applications/${id}/reject/`);
}

export function withdrawApplication(id: number): Promise<Application> {
  return apiPost<Application>(`/applications/${id}/withdraw/`);
}
