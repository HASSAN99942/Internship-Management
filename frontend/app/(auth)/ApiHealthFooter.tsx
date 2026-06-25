"use client";

import { useEffect, useState } from "react";
import { checkHealth } from "@/lib/api/health";
import { ApiError } from "@/lib/api/types";

type State =
  | { state: "loading" }
  | { state: "ok" }
  | { state: "error"; message: string };

/** Small connectivity indicator (the Phase 0 health check, kept visible). */
export function ApiHealthFooter() {
  const [status, setStatus] = useState<State>({ state: "loading" });

  useEffect(() => {
    let cancelled = false;
    checkHealth()
      .then((res) => {
        if (cancelled) return;
        setStatus(
          res.status === "ok"
            ? { state: "ok" }
            : { state: "error", message: `Unexpected status: ${res.status}` },
        );
      })
      .catch((err: unknown) => {
        if (cancelled) return;
        setStatus({
          state: "error",
          message: err instanceof ApiError ? err.message : "API unreachable",
        });
      });
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <p className="mt-6 flex items-center justify-center gap-2 text-xs text-muted-foreground">
      {status.state === "loading" && "Checking API…"}
      {status.state === "ok" && (
        <>
          <span className="inline-block h-2 w-2 rounded-full bg-success" />
          API OK
        </>
      )}
      {status.state === "error" && (
        <>
          <span className="inline-block h-2 w-2 rounded-full bg-destructive" />
          {status.message}
        </>
      )}
    </p>
  );
}
