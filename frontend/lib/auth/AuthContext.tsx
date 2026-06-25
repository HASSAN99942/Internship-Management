"use client";

// Auth provider: owns session state (current user + token lifecycle) and
// exposes login/logout. Token storage is delegated to lib/auth/storage.

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import {
  getMe,
  login as loginRequest,
  logout as logoutRequest,
} from "@/features/auth/api";
import type { LoginRequest, Role, User } from "@/features/auth/types";
import {
  clearTokens,
  getAccessToken,
  getRefreshToken,
  setTokens,
} from "@/lib/auth/storage";

type Status = "loading" | "authenticated" | "unauthenticated";

interface AuthContextValue {
  user: User | null;
  status: Status;
  login: (credentials: LoginRequest) => Promise<User>;
  logout: () => Promise<void>;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

/** Landing route for each role after login / on entering a protected area. */
export const dashboardPathForRole = (role: Role): string => {
  switch (role) {
    case "student":
      return "/student";
    case "company":
      return "/company";
    case "teacher":
      return "/teacher";
    case "admin":
      // Admins are managed through the Django admin site, not a frontend app.
      return "/admin-notice";
  }
};

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [status, setStatus] = useState<Status>("loading");

  const loadUser = useCallback(async () => {
    if (!getAccessToken() && !getRefreshToken()) {
      setUser(null);
      setStatus("unauthenticated");
      return;
    }
    try {
      const me = await getMe();
      setUser(me);
      setStatus("authenticated");
    } catch {
      clearTokens();
      setUser(null);
      setStatus("unauthenticated");
    }
  }, []);

  // Restore the session on first mount.
  useEffect(() => {
    void loadUser();
  }, [loadUser]);

  const login = useCallback(async (credentials: LoginRequest) => {
    const tokens = await loginRequest(credentials);
    setTokens(tokens.access, tokens.refresh);
    const me = await getMe();
    setUser(me);
    setStatus("authenticated");
    return me;
  }, []);

  const logout = useCallback(async () => {
    const refresh = getRefreshToken();
    if (refresh) {
      // Best-effort blacklist; clear locally regardless of the result.
      try {
        await logoutRequest(refresh);
      } catch {
        /* ignore network/expired-token errors on logout */
      }
    }
    clearTokens();
    setUser(null);
    setStatus("unauthenticated");
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({ user, status, login, logout, refreshUser: loadUser }),
    [user, status, login, logout, loadUser],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return ctx;
}
