"use client";

import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { StatusBadge } from "@/components/ui/status-badge";
import { useAuth } from "@/lib/auth/AuthContext";
import { useApplications } from "@/features/applications/hooks";
import { ApplyDialog } from "@/features/applications/components/ApplyDialog";
import { useOffer } from "../hooks";

function DetailItem({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="text-foreground">{value}</dd>
    </div>
  );
}

export function OfferDetailView({ offerId }: { offerId: number }) {
  const { data: offer, isLoading, isError, error } = useOffer(offerId);
  const { user } = useAuth();
  const isStudent = user?.role === "student";
  // Only students need their application list (to detect an existing application).
  const { data: myApplications } = useApplications(isStudent);
  const existingApplication = isStudent
    ? myApplications?.results.find((a) => a.offer.id === offerId)
    : undefined;

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-5 w-28" />
        <Skeleton className="h-64 w-full rounded-xl" />
      </div>
    );
  }

  if (isError || !offer) {
    return (
      <Card className="p-6">
        <p className="text-sm text-destructive">
          {error instanceof Error ? error.message : "Offer not available."}
        </p>
        <Link
          href="/offers"
          className="mt-3 inline-flex items-center gap-1 text-sm font-medium text-primary hover:underline"
        >
          <ArrowLeft className="h-4 w-4" /> Back to offers
        </Link>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      <Link
        href="/offers"
        className="inline-flex items-center gap-1 text-sm font-medium text-primary hover:underline"
      >
        <ArrowLeft className="h-4 w-4" /> Back to offers
      </Link>

      <Card className="p-6">
        <div className="flex items-start justify-between gap-3">
          <div>
            <h1 className="font-heading text-3xl font-bold tracking-tight">
              {offer.title}
            </h1>
            <p className="mt-1 text-muted-foreground">
              {offer.company.company_name || offer.company.email}
            </p>
          </div>
          <StatusBadge status={offer.status} />
        </div>

        <dl className="mt-5 grid grid-cols-2 gap-y-3 text-sm sm:grid-cols-4">
          <DetailItem label="Location" value={offer.location} />
          <DetailItem label="Duration" value={`${offer.duration_weeks} weeks`} />
          <DetailItem label="Positions" value={String(offer.positions)} />
          <DetailItem label="Start date" value={offer.start_date} />
        </dl>

        <section className="mt-6">
          <h2 className="text-sm font-semibold text-foreground">Description</h2>
          <p className="mt-1 whitespace-pre-line text-muted-foreground">
            {offer.description}
          </p>
        </section>

        <section className="mt-4">
          <h2 className="text-sm font-semibold text-foreground">
            Required skills
          </h2>
          <p className="mt-1 whitespace-pre-line text-muted-foreground">
            {offer.skills}
          </p>
        </section>

        {isStudent && (
          <div className="mt-6 border-t pt-5">
            {existingApplication ? (
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <span>You applied to this offer.</span>
                <StatusBadge status={existingApplication.status} />
              </div>
            ) : offer.status === "published" ? (
              <ApplyDialog offerId={offer.id} />
            ) : (
              <p className="text-sm text-muted-foreground">
                This offer is not currently accepting applications.
              </p>
            )}
          </div>
        )}
      </Card>
    </div>
  );
}
