"use client";

import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { StatusBadge } from "@/components/ui/status-badge";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import type { Role } from "@/features/auth/types";
import { useValidateReport } from "../hooks";
import { SubmitReportDialog } from "./SubmitReportDialog";
import { RequestReportChangesDialog } from "./RequestReportChangesDialog";
import type { Report } from "../types";

export function ReportsSection({
  internshipId,
  reports,
  role,
  active,
}: {
  internshipId: number;
  reports: Report[];
  role: Role | undefined;
  active: boolean;
}) {
  const isStudent = role === "student";
  const isSupervisor =
    role === "company" || role === "teacher" || role === "admin";
  const validate = useValidateReport();

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="font-heading text-lg font-semibold">Reports</h2>
        {isStudent && active && <SubmitReportDialog internshipId={internshipId} />}
      </div>

      {reports.length === 0 ? (
        <Card className="p-6 text-center text-sm text-muted-foreground">
          No reports yet.
        </Card>
      ) : (
        <ul className="space-y-3">
          {reports.map((report) => (
            <Card key={report.id} className="p-4">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <p className="font-medium">
                    {report.title}{" "}
                    <span className="text-sm font-normal text-muted-foreground">
                      · {report.period}
                    </span>
                  </p>
                  <p className="mt-1 whitespace-pre-line text-sm text-muted-foreground">
                    {report.content}
                  </p>
                  {report.file && (
                    <a
                      href={report.file}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="mt-1 inline-block text-sm font-medium text-primary hover:underline"
                    >
                      View attachment
                    </a>
                  )}
                  {report.status === "changes_requested" && report.feedback && (
                    <p className="mt-2 rounded-md bg-warning/15 p-2 text-sm text-warning">
                      Feedback: {report.feedback}
                    </p>
                  )}
                </div>
                <StatusBadge status={report.status} />
              </div>

              {active && isSupervisor && report.status === "submitted" && (
                <div className="mt-3 flex flex-wrap gap-2">
                  <ConfirmDialog
                    trigger={<Button size="sm">Validate</Button>}
                    title="Validate report?"
                    confirmLabel="Validate"
                    pending={validate.isPending}
                    onConfirm={() => validate.mutateAsync(report.id)}
                  />
                  <RequestReportChangesDialog reportId={report.id} />
                </div>
              )}
            </Card>
          ))}
        </ul>
      )}
    </div>
  );
}
