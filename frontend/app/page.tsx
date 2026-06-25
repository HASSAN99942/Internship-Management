"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { dashboardPathForRole, useAuth } from "@/lib/auth/AuthContext";

export default function Home() {
  const router = useRouter();
  const { status, user } = useAuth();

  useEffect(() => {
    if (status === "loading") return;
    if (status === "authenticated" && user) {
      router.replace(dashboardPathForRole(user.role));
    } else {
      router.replace("/login");
    }
  }, [status, user, router]);

  return (
    <main className="flex min-h-screen items-center justify-center">
      <p className="text-muted-foreground">Loading…</p>
    </main>
  );
}
