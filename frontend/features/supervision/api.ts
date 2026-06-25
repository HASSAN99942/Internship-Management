// Typed API calls for the supervision-request flow via the central client.

import { apiGet, apiPost } from "@/lib/api/client";
import type { SupervisionRequest } from "./types";

/** GET /supervision-requests/ — requests the caller is party to (role-scoped). */
export function listSupervisionRequests(): Promise<SupervisionRequest[]> {
  return apiGet<SupervisionRequest[]>("/supervision-requests/");
}

/** POST /supervision-requests/ — target is a teacher id (student) or student id (teacher). */
export function createSupervisionRequest(
  targetId: number,
): Promise<SupervisionRequest> {
  return apiPost<SupervisionRequest>("/supervision-requests/", {
    target_id: targetId,
  });
}

export function acceptSupervisionRequest(id: number): Promise<SupervisionRequest> {
  return apiPost<SupervisionRequest>(`/supervision-requests/${id}/accept/`);
}

export function rejectSupervisionRequest(id: number): Promise<SupervisionRequest> {
  return apiPost<SupervisionRequest>(`/supervision-requests/${id}/reject/`);
}

export function cancelSupervisionRequest(id: number): Promise<SupervisionRequest> {
  return apiPost<SupervisionRequest>(`/supervision-requests/${id}/cancel/`);
}
