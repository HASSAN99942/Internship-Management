"use client";

import { Card } from "@/components/ui/card";
import { RatingInput } from "@/components/ui/rating-input";
import type { Criterion } from "../types";

/** Read-only view of a submitted evaluation. */
export function EvaluationCard({
  title,
  criteria,
  scores,
  total,
  comment,
}: {
  title: string;
  criteria: Criterion[];
  scores: Record<string, number>;
  total: number;
  comment: string;
}) {
  return (
    <Card className="space-y-3 p-4">
      <div className="flex items-center justify-between gap-3">
        <h3 className="font-heading font-semibold">{title}</h3>
        <span className="rounded-full bg-primary/10 px-2.5 py-0.5 text-sm font-semibold text-primary">
          {total.toFixed(1)} / {criteria[0]?.max ?? 10}
        </span>
      </div>
      <dl className="space-y-1.5">
        {criteria.map((c) => (
          <div key={c.key} className="flex items-center justify-between gap-3">
            <dt className="text-sm text-muted-foreground">{c.label}</dt>
            <dd>
              <RatingInput
                readOnly
                max={c.max}
                value={scores[c.key] ?? 0}
                label={c.label}
              />
            </dd>
          </div>
        ))}
      </dl>
      {comment && (
        <p className="rounded-md bg-muted p-2.5 text-sm text-foreground">
          {comment}
        </p>
      )}
    </Card>
  );
}
