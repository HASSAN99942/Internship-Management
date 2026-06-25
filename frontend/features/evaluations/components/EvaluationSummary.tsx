"use client";

import { Card } from "@/components/ui/card";
import { cn } from "@/lib/utils";
import type { EvaluationSummary as Summary } from "../types";

function Chip({ label, value }: { label: string; value: number | null }) {
  return (
    <div className="flex flex-col items-center rounded-lg border px-4 py-2">
      <span className="text-xs text-muted-foreground">{label}</span>
      <span
        className={cn(
          "font-heading text-2xl font-bold",
          value === null ? "text-muted-foreground" : "text-foreground",
        )}
      >
        {value === null ? "—" : value.toFixed(1)}
      </span>
    </div>
  );
}

/** Overall + per-evaluator totals for the internship. */
export function EvaluationSummary({ summary }: { summary: Summary }) {
  return (
    <Card className="space-y-3 p-4">
      <h3 className="font-heading font-semibold">Summary</h3>
      <div className="flex flex-wrap gap-3">
        <Chip label="Combined" value={summary.combined} />
        <Chip label="Company" value={summary.company?.total_score ?? null} />
        <Chip label="Teacher" value={summary.teacher?.total_score ?? null} />
        <Chip label="Student" value={summary.student?.total_score ?? null} />
      </div>
      <p className="text-xs text-muted-foreground">
        Combined is the average of the company and teacher assessments. The
        student rating reflects the internship experience.
      </p>
    </Card>
  );
}
