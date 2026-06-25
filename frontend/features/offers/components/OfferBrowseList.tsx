"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Stagger, StaggerItem } from "@/components/ui/motion";
import { useOffers } from "../hooks";
import type { OfferFilters } from "../types";
import { OfferCard } from "./OfferCard";
import { OfferFilterBar } from "./OfferFilterBar";

/** Browse published offers with filters + pagination. Visible to all roles. */
export function OfferBrowseList() {
  const [filters, setFilters] = useState<OfferFilters>({ page: 1 });
  const { data, isLoading, isError, error, isFetching } = useOffers(filters);

  const applyFilters = (next: OfferFilters) => setFilters({ ...next, page: 1 });
  const goToPage = (page: number) => setFilters((prev) => ({ ...prev, page }));

  return (
    <div className="space-y-4">
      <OfferFilterBar initial={filters} onApply={applyFilters} />

      {isLoading && (
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-40 rounded-xl" />
          ))}
        </div>
      )}
      {isError && (
        <p className="text-sm text-destructive">
          {error instanceof Error ? error.message : "Failed to load offers."}
        </p>
      )}

      {data && data.results.length === 0 && (
        <p className="rounded-xl border border-dashed p-8 text-center text-muted-foreground">
          No published offers match your search.
        </p>
      )}

      {data && data.results.length > 0 && (
        <>
          <p className="text-sm text-muted-foreground">
            {data.count} offer{data.count === 1 ? "" : "s"} found
          </p>
          <Stagger className="grid grid-cols-1 gap-4 md:grid-cols-2">
            {data.results.map((offer) => (
              <StaggerItem key={offer.id}>
                <OfferCard offer={offer} href={`/offers/${offer.id}`} />
              </StaggerItem>
            ))}
          </Stagger>

          <div className="flex items-center justify-center gap-4 pt-2">
            <Button
              variant="secondary"
              disabled={!data.previous || isFetching}
              onClick={() => goToPage((filters.page ?? 1) - 1)}
            >
              Previous
            </Button>
            <span className="text-sm text-muted-foreground">
              Page {filters.page ?? 1}
            </span>
            <Button
              variant="secondary"
              disabled={!data.next || isFetching}
              onClick={() => goToPage((filters.page ?? 1) + 1)}
            >
              Next
            </Button>
          </div>
        </>
      )}
    </div>
  );
}
