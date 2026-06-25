import { PendingValidationsList } from "@/features/internships/components/PendingValidationsList";

export default function AgreementsPage() {
  return (
    <div className="space-y-5">
      <div>
        <h1 className="font-heading text-3xl font-bold tracking-tight">
          Agreements to validate
        </h1>
        <p className="mt-1 text-muted-foreground">
          Internship agreements for your students awaiting academic validation.
        </p>
      </div>
      <PendingValidationsList />
    </div>
  );
}
