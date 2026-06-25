"use client";

import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useAuth } from "@/lib/auth/AuthContext";
import type { InternshipStatus } from "@/features/internships/types";
import { useInternshipEvaluations, useSubmitEvaluation } from "../hooks";
import type { EvaluatorType } from "../types";
import { EvaluationCard } from "./EvaluationCard";
import { EvaluationForm } from "./EvaluationForm";
import { EvaluationSummary } from "./EvaluationSummary";

const TITLES: Record<EvaluatorType, string> = {
  company: "Company evaluation",
  teacher: "Academic (teacher) evaluation",
  student: "Student rating",
};

const ORDER: EvaluatorType[] = ["company", "teacher", "student"];

export function EvaluationSection({
  internshipId,
  status,
}: {
  internshipId: number;
  status: InternshipStatus;
}) {
  const { user } = useAuth();
  const { data, isLoading, isError } = useInternshipEvaluations(internshipId);
  const submit = useSubmitEvaluation(internshipId);

  if (isLoading) return <Skeleton className="h-64 w-full rounded-xl" />;
  if (isError || !data) {
    return (
      <Card className="p-6 text-sm text-destructive">
        Could not load evaluations.
      </Card>
    );
  }

  const active = status === "active" || status === "completed";
  if (!active) {
    return (
      <Card className="p-6 text-sm text-muted-foreground">
        Evaluations open once the internship is active.
      </Card>
    );
  }

  const { criteria, evaluations, summary } = data;
  const byType = Object.fromEntries(
    evaluations.map((e) => [e.evaluator_type, e]),
  ) as Partial<Record<EvaluatorType, (typeof evaluations)[number]>>;

  const role = user?.role;
  const myType: EvaluatorType | null =
    role === "company" || role === "teacher" || role === "student"
      ? role
      : null;
  const hasMine = myType ? Boolean(byType[myType]) : false;
  const canSubmit = Boolean(myType) && !hasMine;
  const isStudentSelf = myType === "student";

  return (
    <div className="space-y-4">
      {evaluations.length > 0 && <EvaluationSummary summary={summary} />}

      {ORDER.filter((t) => byType[t]).map((t) => {
        const ev = byType[t]!;
        return (
          <EvaluationCard
            key={t}
            title={TITLES[t]}
            criteria={criteria[t]}
            scores={ev.scores}
            total={ev.total_score}
            comment={ev.comment}
          />
        );
      })}

      {canSubmit && myType && (
        <Card className="space-y-4 p-4">
          <h3 className="font-heading font-semibold">
            {isStudentSelf ? "Rate your internship" : "Your evaluation"}
          </h3>
          <EvaluationForm
            criteria={criteria[myType]}
            pending={submit.isPending}
            submitLabel={isStudentSelf ? "Submit rating" : "Submit evaluation"}
            onSubmit={(input) => submit.mutate(input)}
          />
        </Card>
      )}

      {evaluations.length === 0 && !canSubmit && (
        <Card className="p-6 text-center text-sm text-muted-foreground">
          No evaluations yet.
        </Card>
      )}
    </div>
  );
}
