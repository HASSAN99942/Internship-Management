"use client";

import { FileText } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { StatusBadge } from "@/components/ui/status-badge";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { Stagger, StaggerItem } from "@/components/ui/motion";
import {
  useAcceptApplication,
  useApplications,
  useRejectApplication,
} from "../hooks";
import type { Application } from "../types";

function applicantName(a: Application): string {
  const full = `${a.student.first_name} ${a.student.last_name}`.trim();
  return full || a.student.email;
}

function groupByOffer(applications: Application[]) {
  const groups = new Map<number, { title: string; items: Application[] }>();
  for (const app of applications) {
    const group = groups.get(app.offer.id) ?? {
      title: app.offer.title,
      items: [],
    };
    group.items.push(app);
    groups.set(app.offer.id, group);
  }
  return [...groups.entries()].map(([id, group]) => ({ id, ...group }));
}

export function OfferApplicationsList() {
  const { data, isLoading, isError, error } = useApplications();
  const accept = useAcceptApplication();
  const reject = useRejectApplication();

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
        No applications received yet.
      </p>
    );
  }

  const busy = accept.isPending || reject.isPending;
  const groups = groupByOffer(data.results);

  return (
    <div className="space-y-8">
      {groups.map((group) => (
        <section key={group.id} className="space-y-3">
          <h2 className="font-heading text-lg font-semibold">{group.title}</h2>
          <Stagger className="space-y-3">
            {group.items.map((app) => (
              <StaggerItem key={app.id}>
                <Card className="p-5">
                  <div className="flex flex-wrap items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="font-medium text-foreground">
                        {applicantName(app)}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {app.student.email}
                      </p>
                    </div>
                    <StatusBadge status={app.status} />
                  </div>

                  <p className="mt-3 whitespace-pre-line text-sm text-muted-foreground">
                    {app.cover_message}
                  </p>

                  {app.cv_file && (
                    <a
                      href={app.cv_file}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="mt-3 inline-flex items-center gap-1.5 text-sm font-medium text-primary hover:underline"
                    >
                      <FileText className="h-4 w-4" /> View CV
                    </a>
                  )}

                  {app.status === "pending" && (
                    <div className="mt-4 flex flex-wrap gap-2 border-t pt-4">
                      <ConfirmDialog
                        trigger={<Button disabled={busy}>Accept</Button>}
                        title="Accept this application?"
                        description="This creates an internship agreement pending the teacher's academic validation."
                        confirmLabel="Accept"
                        pending={accept.isPending}
                        onConfirm={() => accept.mutateAsync(app.id)}
                      />
                      <ConfirmDialog
                        trigger={
                          <Button variant="outline" disabled={busy}>
                            Reject
                          </Button>
                        }
                        title="Reject this application?"
                        description="The applicant will see their application marked as rejected."
                        confirmLabel="Reject"
                        confirmVariant="destructive"
                        pending={reject.isPending}
                        onConfirm={() => reject.mutateAsync(app.id)}
                      />
                    </div>
                  )}
                </Card>
              </StaggerItem>
            ))}
          </Stagger>
        </section>
      ))}
    </div>
  );
}
