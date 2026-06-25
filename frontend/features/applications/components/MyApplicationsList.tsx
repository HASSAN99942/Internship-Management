"use client";

import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { StatusBadge } from "@/components/ui/status-badge";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { Stagger, StaggerItem } from "@/components/ui/motion";
import { useApplications, useWithdrawApplication } from "../hooks";
import { ApplicationStatusTimeline } from "./ApplicationStatusTimeline";

export function MyApplicationsList() {
  const { data, isLoading, isError, error } = useApplications();
  const withdraw = useWithdrawApplication();

  if (isLoading) {
    return (
      <div className="space-y-3">
        {Array.from({ length: 3 }).map((_, i) => (
          <Skeleton key={i} className="h-32 rounded-xl" />
        ))}
      </div>
    );
  }
  if (isError) {
    return (
      <p className="text-sm text-destructive">
        {error instanceof Error ? error.message : "Failed to load applications."}
      </p>
    );
  }
  if (!data || data.results.length === 0) {
    return (
      <p className="rounded-xl border border-dashed p-8 text-center text-muted-foreground">
        You haven&apos;t applied to any offers yet.{" "}
        <Link href="/offers" className="font-medium text-primary hover:underline">
          Browse offers
        </Link>
        .
      </p>
    );
  }

  return (
    <Stagger className="space-y-3">
      {data.results.map((application) => (
        <StaggerItem key={application.id}>
          <Card className="p-5">
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div className="min-w-0">
                <Link
                  href={`/offers/${application.offer.id}`}
                  className="font-heading font-semibold text-foreground hover:text-primary"
                >
                  {application.offer.title}
                </Link>
                <p className="mt-2 line-clamp-2 text-sm text-muted-foreground">
                  {application.cover_message}
                </p>
              </div>
              <div className="flex flex-col items-end gap-3">
                <StatusBadge status={application.status} />
                {application.status === "pending" && (
                  <ConfirmDialog
                    trigger={
                      <Button variant="ghost" size="sm" className="text-destructive hover:bg-destructive/10 hover:text-destructive">
                        Withdraw
                      </Button>
                    }
                    title="Withdraw application?"
                    description="This cannot be undone. The company will no longer see your application."
                    confirmLabel="Withdraw"
                    confirmVariant="destructive"
                    pending={withdraw.isPending}
                    onConfirm={() => withdraw.mutateAsync(application.id)}
                  />
                )}
              </div>
            </div>
            <div className="mt-4 border-t pt-4">
              <ApplicationStatusTimeline application={application} />
            </div>
          </Card>
        </StaggerItem>
      ))}
    </Stagger>
  );
}
