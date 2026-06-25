"use client";

import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { StatusBadge } from "@/components/ui/status-badge";
import {
  useAcceptSupervisionRequest,
  useCancelSupervisionRequest,
  useRejectSupervisionRequest,
  useSupervisionRequests,
} from "../hooks";
import type { SupervisionParty } from "../types";

function partyName(p: SupervisionParty) {
  return `${p.first_name} ${p.last_name}`.trim() || p.email;
}

/** Teacher's pending supervision requests: incoming (accept/reject) + outgoing (cancel). */
export function SupervisionRequestsPanel() {
  const { data: requests, isLoading } = useSupervisionRequests();
  const accept = useAcceptSupervisionRequest();
  const reject = useRejectSupervisionRequest();
  const cancel = useCancelSupervisionRequest();

  if (isLoading) return <Skeleton className="h-32 w-full rounded-xl" />;

  const pending = (requests ?? []).filter((r) => r.status === "pending");
  if (pending.length === 0) return null;

  return (
    <Card className="space-y-3 p-4">
      <h2 className="font-heading text-lg font-semibold">Supervision requests</h2>
      <ul className="space-y-2">
        {pending.map((r) => {
          const incoming = r.initiated_by === "student";
          return (
            <li
              key={r.id}
              className="flex items-center justify-between gap-3 rounded-lg border p-3"
            >
              <div className="min-w-0">
                <p className="font-medium">{partyName(r.student)}</p>
                <p className="text-xs text-muted-foreground">
                  {incoming
                    ? "Requested you as supervisor"
                    : "You invited this student — awaiting their response"}
                </p>
              </div>
              <div className="flex items-center gap-2">
                {incoming ? (
                  <>
                    <Button
                      size="sm"
                      disabled={accept.isPending}
                      onClick={() => accept.mutate(r.id)}
                    >
                      Accept
                    </Button>
                    <Button
                      size="sm"
                      variant="secondary"
                      disabled={reject.isPending}
                      onClick={() => reject.mutate(r.id)}
                    >
                      Reject
                    </Button>
                  </>
                ) : (
                  <>
                    <StatusBadge status="pending" />
                    <Button
                      size="sm"
                      variant="secondary"
                      disabled={cancel.isPending}
                      onClick={() => cancel.mutate(r.id)}
                    >
                      Cancel
                    </Button>
                  </>
                )}
              </div>
            </li>
          );
        })}
      </ul>
    </Card>
  );
}
