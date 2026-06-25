"use client";

import Link from "next/link";
import { ClipboardCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { StatusBadge } from "@/components/ui/status-badge";
import { Stagger, StaggerItem } from "@/components/ui/motion";
import { useInternships } from "@/features/internships/hooks";
import { partyName } from "@/features/internships/format";

export function EvaluationsOverview() {
  const { data, isLoading, isError, error } = useInternships();

  if (isLoading) {
    return (
      <div className="space-y-3">
        {Array.from({ length: 2 }).map((_, i) => (
          <Skeleton key={i} className="h-28 rounded-xl" />
        ))}
      </div>
    );
  }
  if (isError) {
    return (
      <p className="text-sm text-destructive">
        {error instanceof Error ? error.message : "Failed to load internships."}
      </p>
    );
  }

  const eligible = (data?.results ?? []).filter(
    (i) => i.status === "active" || i.status === "completed",
  );

  if (eligible.length === 0) {
    return (
      <p className="rounded-xl border border-dashed p-8 text-center text-muted-foreground">
        No active or completed internships yet. Evaluations open once an
        internship is active.
      </p>
    );
  }

  return (
    <Stagger className="space-y-3">
      {eligible.map((internship) => (
        <StaggerItem key={internship.id}>
          <Card className="p-5">
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div className="min-w-0">
                <p className="font-heading font-semibold">
                  {internship.offer_title}
                </p>
                <p className="mt-1 text-xs text-muted-foreground">
                  {partyName(internship.student)} ·{" "}
                  {partyName(internship.company)}
                  {internship.teacher
                    ? ` · ${partyName(internship.teacher)}`
                    : ""}
                </p>
                <p className="mt-0.5 text-xs text-muted-foreground">
                  {internship.start_date} → {internship.end_date}
                </p>
              </div>
              <div className="flex shrink-0 flex-col items-end gap-2">
                <StatusBadge status={internship.status} />
                <Button asChild size="sm" variant="outline">
                  <Link href={`/internships/${internship.id}?tab=evaluation`}>
                    <ClipboardCheck className="mr-2 h-4 w-4" />
                    View evaluations
                  </Link>
                </Button>
              </div>
            </div>
          </Card>
        </StaggerItem>
      ))}
    </Stagger>
  );
}
