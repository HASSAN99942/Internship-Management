"use client";

import Link from "next/link";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { StatusBadge } from "@/components/ui/status-badge";
import { Stagger, StaggerItem } from "@/components/ui/motion";
import { useInternships } from "../hooks";
import { partyName } from "../format";

export function InternshipsList() {
  const { data, isLoading, isError, error } = useInternships();

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
        {error instanceof Error ? error.message : "Failed to load internships."}
      </p>
    );
  }
  if (!data || data.results.length === 0) {
    return (
      <p className="rounded-xl border border-dashed p-8 text-center text-muted-foreground">
        No internships yet.
      </p>
    );
  }

  return (
    <Stagger className="space-y-3">
      {data.results.map((internship) => (
        <StaggerItem key={internship.id}>
          <Card className="p-5">
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div className="min-w-0">
                <Link
                  href={`/internships/${internship.id}`}
                  className="font-heading font-semibold text-foreground hover:text-primary"
                >
                  {internship.offer_title}
                </Link>
                <p className="mt-1 text-xs text-muted-foreground">
                  {partyName(internship.student)} · {partyName(internship.company)}{" "}
                  · {internship.start_date} → {internship.end_date}
                </p>
              </div>
              <StatusBadge status={internship.status} />
            </div>
          </Card>
        </StaggerItem>
      ))}
    </Stagger>
  );
}
