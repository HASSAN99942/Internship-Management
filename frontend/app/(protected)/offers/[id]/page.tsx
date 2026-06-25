import { notFound } from "next/navigation";
import { OfferDetailView } from "@/features/offers/components/OfferDetailView";

export default async function OfferDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const offerId = Number.parseInt(id, 10);
  if (!Number.isFinite(offerId)) notFound();
  return <OfferDetailView offerId={offerId} />;
}
