import { notFound } from "next/navigation";
import { InternshipDetailView } from "@/features/internships/components/InternshipDetailView";

export default async function InternshipDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const internshipId = Number.parseInt(id, 10);
  if (!Number.isFinite(internshipId)) notFound();
  return <InternshipDetailView internshipId={internshipId} />;
}
