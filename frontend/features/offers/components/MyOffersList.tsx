"use client";

import Link from "next/link";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { StatusBadge } from "@/components/ui/status-badge";
import { Stagger, StaggerItem } from "@/components/ui/motion";
import {
  useCloseOffer,
  useDeleteOffer,
  useMyOffers,
  usePublishOffer,
} from "../hooks";
import type { Offer } from "../types";

function OfferRow({ offer }: { offer: Offer }) {
  const publish = usePublishOffer();
  const close = useCloseOffer();
  const remove = useDeleteOffer();
  const busy = publish.isPending || close.isPending || remove.isPending;

  return (
    <Card className="p-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="min-w-0">
          <div className="flex items-center gap-2">
            <Link
              href={`/offers/${offer.id}`}
              className="font-heading font-semibold text-foreground hover:text-primary"
            >
              {offer.title}
            </Link>
            <StatusBadge status={offer.status} />
          </div>
          <p className="mt-1 text-xs text-muted-foreground">
            {offer.location} · {offer.duration_weeks} weeks · {offer.positions}{" "}
            position{offer.positions === 1 ? "" : "s"}
          </p>
        </div>

        <div className="flex flex-wrap gap-2">
          <Button variant="secondary" disabled={busy} asChild>
            <Link href={`/company/offers/${offer.id}/edit`}>Edit</Link>
          </Button>
          {offer.status === "draft" && (
            <Button
              disabled={busy}
              onClick={() =>
                publish.mutate(offer.id, {
                  onSuccess: () => toast.success("Offer published"),
                })
              }
            >
              Publish
            </Button>
          )}
          {offer.status !== "closed" && (
            <Button
              variant="outline"
              disabled={busy}
              onClick={() =>
                close.mutate(offer.id, {
                  onSuccess: () => toast.success("Offer closed"),
                })
              }
            >
              Close
            </Button>
          )}
          <Button
            variant="ghost"
            className="text-destructive hover:bg-destructive/10 hover:text-destructive"
            disabled={busy}
            onClick={() => {
              if (confirm(`Delete “${offer.title}”? This cannot be undone.`)) {
                remove.mutate(offer.id, {
                  onSuccess: () => toast.success("Offer deleted"),
                });
              }
            }}
          >
            Delete
          </Button>
        </div>
      </div>
    </Card>
  );
}

export function MyOffersList() {
  const { data, isLoading, isError, error } = useMyOffers();

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="font-heading text-3xl font-bold tracking-tight">
          My offers
        </h1>
        <Button asChild>
          <Link href="/company/offers/new">New offer</Link>
        </Button>
      </div>

      {isLoading && (
        <div className="space-y-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-24 rounded-xl" />
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
          You haven’t created any offers yet.
        </p>
      )}
      {data && data.results.length > 0 && (
        <Stagger className="space-y-3">
          {data.results.map((offer) => (
            <StaggerItem key={offer.id}>
              <OfferRow offer={offer} />
            </StaggerItem>
          ))}
        </Stagger>
      )}
    </div>
  );
}
