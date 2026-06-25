import { notFound } from "next/navigation";
import { EditOfferForm } from "@/features/offers/components/EditOfferForm";

export default async function EditOfferPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const offerId = Number.parseInt(id, 10);
  if (!Number.isFinite(offerId)) notFound();
  return (
    <div className="space-y-5">
      <h1 className="font-heading text-3xl font-bold tracking-tight">
        Edit offer
      </h1>
      <EditOfferForm offerId={offerId} />
    </div>
  );
}
