"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Field } from "@/components/ui/field";
import { RatingInput } from "@/components/ui/rating-input";
import type { Criterion, SubmitEvaluationInput } from "../types";

/**
 * Criteria-driven rating form (controlled). Criteria arrive from the API, so a
 * controlled form is cleaner than a static schema; the backend validates
 * authoritatively. Every criterion must be rated before submitting.
 */
export function EvaluationForm({
  criteria,
  pending,
  submitLabel = "Submit evaluation",
  onSubmit,
}: {
  criteria: Criterion[];
  pending: boolean;
  submitLabel?: string;
  onSubmit: (input: SubmitEvaluationInput) => void;
}) {
  const [scores, setScores] = useState<Record<string, number>>({});
  const [comment, setComment] = useState("");
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const unrated = criteria.find((c) => !scores[c.key]);
    if (unrated) {
      setError(`Please rate "${unrated.label}".`);
      return;
    }
    setError(null);
    onSubmit({ scores, comment });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-3">
        {criteria.map((c) => (
          <div
            key={c.key}
            className="flex items-center justify-between gap-4 rounded-lg border p-3"
          >
            <span className="text-sm font-medium">{c.label}</span>
            <RatingInput
              label={c.label}
              max={c.max}
              value={scores[c.key] ?? 0}
              onChange={(v) => setScores((s) => ({ ...s, [c.key]: v }))}
            />
          </div>
        ))}
      </div>

      <Field label="Comment" htmlFor="evaluation-comment">
        <Textarea
          id="evaluation-comment"
          rows={4}
          value={comment}
          onChange={(e) => setComment(e.target.value)}
          placeholder="Optional feedback…"
        />
      </Field>

      {error && (
        <p role="alert" className="text-sm text-destructive">
          {error}
        </p>
      )}

      <Button type="submit" disabled={pending}>
        {pending ? "Submitting…" : submitLabel}
      </Button>
    </form>
  );
}
