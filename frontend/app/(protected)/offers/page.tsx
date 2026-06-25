import { OfferBrowseList } from "@/features/offers/components/OfferBrowseList";

export default function OffersBrowsePage() {
  return (
    <div className="space-y-5">
      <div>
        <h1 className="font-heading text-3xl font-bold tracking-tight">
          Internship offers
        </h1>
        <p className="mt-1 text-muted-foreground">
          Browse and filter published opportunities.
        </p>
      </div>
      <OfferBrowseList />
    </div>
  );
}
