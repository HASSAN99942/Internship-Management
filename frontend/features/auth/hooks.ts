"use client";

// React Query hooks for auth. Login/logout delegate to the AuthContext so
// session state stays in one place; register and updateMe are plain mutations.

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { getMe, listTeachers, register, updateMe } from "./api";
import type { MeUpdateRequest, RegisterRequest } from "./types";
import { useAuth } from "@/lib/auth/AuthContext";

export const meQueryKey = ["me"] as const;
export const teachersQueryKey = ["teachers"] as const;

/** Selectable teachers for the student's supervisor picker. */
export function useTeachers(enabled = true) {
  return useQuery({
    queryKey: teachersQueryKey,
    queryFn: listTeachers,
    enabled,
    staleTime: 5 * 60 * 1000,
  });
}

/** Read the current user from the API (separate from the context cache). */
export function useMe(enabled = true) {
  return useQuery({
    queryKey: meQueryKey,
    queryFn: getMe,
    enabled,
  });
}

export function useRegister() {
  return useMutation({
    mutationFn: (payload: RegisterRequest) => register(payload),
  });
}

export function useLogin() {
  const { login } = useAuth();
  return useMutation({
    mutationFn: login,
  });
}

export function useLogout() {
  const { logout } = useAuth();
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: logout,
    onSuccess: () => queryClient.clear(),
  });
}

export function useUpdateMe() {
  const queryClient = useQueryClient();
  const { refreshUser } = useAuth();
  return useMutation({
    mutationFn: (payload: MeUpdateRequest) => updateMe(payload),
    onSuccess: async () => {
      await refreshUser();
      await queryClient.invalidateQueries({ queryKey: meQueryKey });
    },
  });
}
