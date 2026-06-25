"use client";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/lib/auth/AuthContext";
import type { StudentProfile } from "@/features/auth/types";
import {
  useAcceptSupervisionRequest,
  useCancelSupervisionRequest,
  useRejectSupervisionRequest,
  useSupervisionRequests,
} from "@/features/supervision/hooks";
import type { SupervisionParty } from "@/features/supervision/types";
import { RequestSupervisorDialog } from "@/features/supervision/components/RequestSupervisorDialog";

function partyName(p: { first_name: string; last_name: string; email: string }) {
  return `${p.first_name} ${p.last_name}`.trim() || p.email;
}

/**
 * Student's academic supervisor card. Supervision is a mutual-consent flow:
 * the student requests a teacher (or accepts a teacher's invitation), and the
 * other party validates. The confirmed supervisor validates the internship.
 */
export function SupervisorCard() {
  const { user } = useAuth();
  const isStudent = user?.role === "student";
  const profile = isStudent ? (user!.profile as StudentProfile | null) : null;
  const current: SupervisionParty | null = profile?.assigned_teacher ?? null;

  const { data: requests, isLoading } = useSupervisionRequests();
  const accept = useAcceptSupervisionRequest();
  const reject = useRejectSupervisionRequest();
  const cancel = useCancelSupervisionRequest();

  if (!isStudent) return null;

  const pending = (requests ?? []).find((r) => r.status === "pending") ?? null;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-xl">Academic supervisor</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {current ? (
          <p className="text-sm text-muted-foreground">
            Your supervisor is{" "}
            <span className="font-medium text-foreground">
              {partyName(current)}
            </span>
            . They validate your internship agreement.
          </p>
        ) : isLoading ? (
          <Skeleton className="h-10 w-full rounded-md" />
        ) : pending ? (
          pending.initiated_by === "student" ? (
            <div className="flex flex-wrap items-center justify-between gap-3">
              <p className="text-sm text-muted-foreground">
                Request pending — waiting for{" "}
                <span className="font-medium text-foreground">
                  {partyName(pending.teacher)}
                </span>{" "}
                to accept.
              </p>
              <Button
                variant="secondary"
                size="sm"
                disabled={cancel.isPending}
                onClick={() => cancel.mutate(pending.id)}
              >
                Cancel request
              </Button>
            </div>
          ) : (
            <div className="space-y-3">
              <p className="text-sm text-muted-foreground">
                <span className="font-medium text-foreground">
                  {partyName(pending.teacher)}
                </span>{" "}
                invited you to be your academic supervisor.
              </p>
              <div className="flex gap-2">
                <Button
                  size="sm"
                  disabled={accept.isPending}
                  onClick={() => accept.mutate(pending.id)}
                >
                  Accept
                </Button>
                <Button
                  size="sm"
                  variant="secondary"
                  disabled={reject.isPending}
                  onClick={() => reject.mutate(pending.id)}
                >
                  Decline
                </Button>
              </div>
            </div>
          )
        ) : (
          <div className="space-y-3">
            <p className="text-sm text-muted-foreground">
              You don&apos;t have a supervisor yet. Request a teacher to
              supervise and validate your internship.
            </p>
            <RequestSupervisorDialog />
          </div>
        )}
      </CardContent>
    </Card>
  );
}
