// Typed API calls for auth. Thin wrappers over the central client.

import { apiFetch, apiGet, apiPatch, apiPost } from "@/lib/api/client";
import type {
  LoginRequest,
  MeUpdateRequest,
  RegisterRequest,
  TeacherOption,
  TokenPair,
  User,
} from "./types";

/** POST /api/v1/auth/register/ — creates the user + role profile. */
export function register(payload: RegisterRequest): Promise<User> {
  return apiPost<User>("/auth/register/", payload, { auth: false });
}

/** POST /api/v1/auth/login/ — returns access + refresh (+ role). */
export function login(payload: LoginRequest): Promise<TokenPair> {
  return apiPost<TokenPair>("/auth/login/", payload, { auth: false });
}

/** POST /api/v1/auth/logout/ — blacklists the refresh token. */
export function logout(refresh: string): Promise<void> {
  return apiFetch<void>("/auth/logout/", {
    method: "POST",
    json: { refresh },
  });
}

/** GET /api/v1/me/ — the authenticated user with its profile. */
export function getMe(): Promise<User> {
  return apiGet<User>("/me/");
}

/** PATCH /api/v1/me/ — partial update of own user + profile. */
export function updateMe(payload: MeUpdateRequest): Promise<User> {
  return apiPatch<User>("/me/", payload);
}

/** GET /api/v1/teachers/ — selectable teachers for the supervisor picker.
 *  Public, so it works on the registration page (no token sent). */
export function listTeachers(): Promise<TeacherOption[]> {
  return apiGet<TeacherOption[]>("/teachers/", { auth: false });
}
