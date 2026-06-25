// Central API client and single source of truth for auth on requests.
//
// - Attaches the JWT access token to every request.
// - On a 401, transparently refreshes the access token using the refresh
//   token and retries the original request exactly once.
// - Concurrent 401s share a single in-flight refresh (single-flight) so we
//   never fire multiple refreshes at the same time.

import {
  clearTokens,
  getAccessToken,
  getRefreshToken,
  setAccessToken,
} from "@/lib/auth/storage";
import { ApiError } from "./types";

const BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://192.168.2.149:8000";

const API_PREFIX = "/api/v1";

// A JSON request body: any serializable value (objects, arrays, ...). It is
// JSON.stringify'd before sending, so `unknown` is the honest type here.
type Json = unknown;

interface RequestOptions extends Omit<RequestInit, "body"> {
  /** Value serialized as the JSON request body. */
  json?: Json;
  /** Multipart body (file uploads). When set, Content-Type is left to the browser. */
  formData?: FormData;
  /** Skip auth header + refresh handling (used by login/register/refresh). */
  auth?: boolean;
  /** Internal: marks a request that has already been retried after refresh. */
  _retried?: boolean;
}

// In-flight refresh shared across concurrent callers.
let refreshPromise: Promise<string | null> | null = null;

function buildUrl(path: string): string {
  // Allow callers to pass either a full "/api/v1/..." path or a short path.
  if (path.startsWith("/api/")) return `${BASE_URL}${path}`;
  return `${BASE_URL}${API_PREFIX}${path}`;
}

async function refreshAccessToken(): Promise<string | null> {
  const refresh = getRefreshToken();
  if (!refresh) return null;

  if (!refreshPromise) {
    refreshPromise = fetch(buildUrl("/auth/refresh/"), {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify({ refresh }),
    })
      .then(async (res) => {
        if (!res.ok) return null;
        const data = (await res.json()) as { access?: string };
        if (!data.access) return null;
        setAccessToken(data.access);
        return data.access;
      })
      .catch(() => null)
      .finally(() => {
        refreshPromise = null;
      });
  }

  return refreshPromise;
}

/**
 * Perform a JSON request against the API and return the parsed body.
 *
 * @throws {ApiError} on a non-2xx response (after a refresh attempt on 401)
 *   or a network failure.
 */
export async function apiFetch<T>(
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  const { json, formData, headers, auth = true, _retried = false, ...rest } =
    options;

  const finalHeaders: Record<string, string> = {
    Accept: "application/json",
    ...(headers as Record<string, string> | undefined),
  };
  // Let the browser set the multipart boundary for FormData bodies.
  if (!formData) {
    finalHeaders["Content-Type"] = "application/json";
  }

  if (auth) {
    const token = getAccessToken();
    if (token) finalHeaders.Authorization = `Bearer ${token}`;
  }

  let response: Response;
  try {
    response = await fetch(buildUrl(path), {
      ...rest,
      headers: finalHeaders,
      body: formData ?? (json !== undefined ? JSON.stringify(json) : undefined),
    });
  } catch (cause) {
    throw new ApiError(`Network error while requesting ${path}`, 0, cause);
  }

  // Attempt a one-time refresh + retry on 401 for authed requests.
  if (response.status === 401 && auth && !_retried) {
    const newAccess = await refreshAccessToken();
    if (newAccess) {
      return apiFetch<T>(path, { ...options, _retried: true });
    }
    // Refresh failed — session is no longer valid.
    clearTokens();
  }

  const text = await response.text();
  const data: unknown = text ? safeJsonParse(text) : null;

  if (!response.ok) {
    throw new ApiError(
      extractMessage(data) ?? `Request to ${path} failed (${response.status})`,
      response.status,
      data,
    );
  }

  return data as T;
}

function safeJsonParse(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

// Read a human message out of our standard error envelope when present.
function extractMessage(data: unknown): string | null {
  if (data && typeof data === "object" && "error" in data) {
    const err = (data as { error?: { message?: string } }).error;
    if (err?.message) return err.message;
  }
  return null;
}

export function apiGet<T>(path: string, options?: RequestOptions): Promise<T> {
  return apiFetch<T>(path, { ...options, method: "GET" });
}

export function apiPost<T>(
  path: string,
  json?: Json,
  options?: RequestOptions,
): Promise<T> {
  return apiFetch<T>(path, { ...options, method: "POST", json });
}

export function apiPatch<T>(
  path: string,
  json?: Json,
  options?: RequestOptions,
): Promise<T> {
  return apiFetch<T>(path, { ...options, method: "PATCH", json });
}

/** POST a multipart/form-data body (file uploads). */
export function apiUpload<T>(
  path: string,
  formData: FormData,
  options?: RequestOptions,
): Promise<T> {
  return apiFetch<T>(path, { ...options, method: "POST", formData });
}
