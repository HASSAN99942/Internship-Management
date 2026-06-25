import { Card } from "@/components/ui/card";
import { OfferForm } from "@/features/offers/components/OfferForm";

export default function NewOfferPage() {
  return (
    <div className="space-y-5">
      <h1 className="font-heading text-3xl font-bold tracking-tight">
        New offer
      </h1>
      <Card className="p-6">
        <OfferForm />
      </Card>
    </div>
  );
}
