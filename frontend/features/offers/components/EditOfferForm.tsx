"use client";

import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useOffer } from "../hooks";
import { OfferForm } from "./OfferForm";

/** Loads an offer by id, then renders the edit form. */
export function EditOfferForm({ offerId }: { offerId: number }) {
  const { data: offer, isLoading, isError, error } = useOffer(offerId);

  if (isLoading) return <Skeleton className="h-96 w-full rounded-xl" />;
  if (isError || !offer) {
    return (
      <Card className="p-6">
        <p className="text-sm text-destructive">
          {error instanceof Error ? error.message : "Offer not available."}
        </p>
      </Card>
    );
  }

  return (
    <Card className="p-6">
      <OfferForm offer={offer} />
    </Card>
  );
}
