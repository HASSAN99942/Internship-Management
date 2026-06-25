"use client";

// Client-side route protection. Tokens live in browser storage (CLAUDE.md),
// which Next middleware can't read server-side, so the guard runs here.
// - Unauthenticated users are sent to /login.
// - Authenticated users in the wrong role's area are sent to their own dashboard.
// Authenticated content is rendered inside the shared AppShell.

import { useEffect } from "react";
import { usePathname, useRouter } from "next/navigation";
import { AppShell } from "@/components/layout/AppShell";
import { dashboardPathForRole, useAuth } from "@/lib/auth/AuthContext";
import type { Role } from "@/features/auth/types";

// First path segment -> the role allowed to view it.
const SEGMENT_ROLE: Record<string, Role> = {
  student: "student",
  company: "company",
  teacher: "teacher",
  "admin-notice": "admin",
  // Student-only top-level area; /internships is shared (role-scoped server-side).
  applications: "student",
};

export default function ProtectedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const { status, user } = useAuth();

  const segment = pathname.split("/").filter(Boolean)[0] ?? "";
  const requiredRole = SEGMENT_ROLE[segment];

  useEffect(() => {
    if (status === "loading") return;
    if (status === "unauthenticated" || !user) {
      router.replace("/login");
      return;
    }
    if (requiredRole && user.role !== requiredRole) {
      router.replace(dashboardPathForRole(user.role));
    }
  }, [status, user, requiredRole, router]);

  // While resolving auth or before a redirect settles, avoid flashing content.
  if (status !== "authenticated" || !user) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <p className="text-muted-foreground">Loading…</p>
      </div>
    );
  }
  if (requiredRole && user.role !== requiredRole) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <p className="text-muted-foreground">Redirecting…</p>
      </div>
    );
  }

  return <AppShell>{children}</AppShell>;
}
