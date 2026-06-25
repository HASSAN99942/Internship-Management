// Typed call for the health-check endpoint (public; no auth).

import { apiGet } from "./client";
import type { HealthResponse } from "./types";

/** Calls `GET /api/v1/health/` and returns the parsed response. */
export function checkHealth(): Promise<HealthResponse> {
  return apiGet<HealthResponse>("/health/", { auth: false });
}
