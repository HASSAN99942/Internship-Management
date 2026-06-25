"use client";

import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { StatusBadge } from "@/components/ui/status-badge";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { Stagger, StaggerItem } from "@/components/ui/motion";
import { useInternships, useValidateInternship } from "../hooks";
import { partyName } from "../format";

export function PendingValidationsList() {
  const { data, isLoading, isError, error } = useInternships();
  const validate = useValidateInternship();

  if (isLoading) {
    return (
      <div className="space-y-3">
        {Array.from({ length: 3 }).map((_, i) => (
          <Skeleton key={i} className="h-28 rounded-xl" />
        ))}
      </div>
    );
  }
  if (isError) {
    return (
      <p className="text-sm text-destructive">
        {error instanceof Error ? error.message : "Failed to load agreements."}
      </p>
    );
  }

  const pending =
    data?.results.filter(
      (i) => i.status === "pending_academic_validation",
    ) ?? [];

  if (pending.length === 0) {
    return (
      <p className="rounded-xl border border-dashed p-8 text-center text-muted-foreground">
        No agreements awaiting your validation.
      </p>
    );
  }

  return (
    <Stagger className="space-y-3">
      {pending.map((internship) => (
        <StaggerItem key={internship.id}>
          <Card className="p-5">
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div className="min-w-0">
                <p className="font-heading font-semibold text-foreground">
                  {internship.offer_title}
                </p>
                <p className="mt-1 text-xs text-muted-foreground">
                  {partyName(internship.student)} ·{" "}
                  {partyName(internship.company)} · {internship.start_date} →{" "}
                  {internship.end_date}
                </p>
              </div>
              <div className="flex items-center gap-3">
                <StatusBadge status={internship.status} />
                <ConfirmDialog
                  trigger={<Button disabled={validate.isPending}>Validate</Button>}
                  title="Validate this agreement?"
                  description="Validating activates the internship so the mission can begin."
                  confirmLabel="Validate"
                  pending={validate.isPending}
                  onConfirm={() => validate.mutateAsync(internship.id)}
                />
              </div>
            </div>
          </Card>
        </StaggerItem>
      ))}
    </Stagger>
  );
}
