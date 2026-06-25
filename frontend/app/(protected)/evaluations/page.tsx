import { EvaluationsOverview } from "@/features/evaluations/components/EvaluationsOverview";

export default function EvaluationsPage() {
  return (
    <div className="space-y-5">
      <div>
        <h1 className="font-heading text-3xl font-bold tracking-tight">
          Evaluations
        </h1>
        <p className="mt-1 text-muted-foreground">
          View and submit evaluations for your internships.
        </p>
      </div>
      <EvaluationsOverview />
    </div>
  );
}
