import { cn } from "@/lib/utils";
import type { Application } from "../types";

function formatDate(iso: string | null): string {
  if (!iso) return "";
  return new Date(iso).toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

const DECISION_LABEL: Record<Application["status"], string> = {
  pending: "Awaiting decision",
  accepted: "Accepted",
  rejected: "Rejected",
  withdrawn: "Withdrawn",
};

/** Compact submitted → decision timeline for a student's application (APP-07). */
export function ApplicationStatusTimeline({
  application,
}: {
  application: Application;
}) {
  const decided = application.status !== "pending";
  const steps = [
    { label: "Submitted", at: application.created_at, done: true },
    {
      label: DECISION_LABEL[application.status],
      at: application.decided_at,
      done: decided,
    },
  ];

  return (
    <ol className="space-y-2">
      {steps.map((step) => (
        <li key={step.label} className="flex items-center gap-3 text-sm">
          <span
            className={cn(
              "h-2.5 w-2.5 shrink-0 rounded-full",
              step.done ? "bg-primary" : "bg-muted-foreground/30",
            )}
          />
          <span className="text-foreground">{step.label}</span>
          {step.at && (
            <span className="text-xs text-muted-foreground">
              {formatDate(step.at)}
            </span>
          )}
        </li>
      ))}
    </ol>
  );
}
