import { OfferApplicationsList } from "@/features/applications/components/OfferApplicationsList";

export default function CompanyApplicationsPage() {
  return (
    <div className="space-y-5">
      <div>
        <h1 className="font-heading text-3xl font-bold tracking-tight">
          Applications
        </h1>
        <p className="mt-1 text-muted-foreground">
          Review applications to your offers and accept or reject them.
        </p>
      </div>
      <OfferApplicationsList />
    </div>
  );
}
